
import os
import re
import json
import logging
from pathlib import Path
from datetime import date, datetime

import pandas as pd
import mysql.connector
from flask import Flask, render_template, request, jsonify
from werkzeug.utils import secure_filename


app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 50 * 1024 * 1024  # 50 MB

# ---------------- DATABASE CONFIGURATION ----------------

DB_HOST = "localhost"
DB_USER = "root"
DB_PASSWORD = "Manasa@02"
DB_NAME = "school"

ALLOWED_EXTENSIONS = {".csv", ".tsv", ".xlsx", ".xls", ".json"}

# ---------------- LOG CONFIGURATION ----------------

os.makedirs("logs", exist_ok=True)

logging.basicConfig(
    filename="logs/success.log",
    level=logging.INFO,
    format="%(asctime)s - %(message)s"
)

error_logger = logging.getLogger("import_errors")
error_logger.setLevel(logging.ERROR)

error_handler = logging.FileHandler(
    "logs/unsuccess.log",
    encoding="utf-8"
)
error_handler.setFormatter(
    logging.Formatter("%(asctime)s - %(message)s")
)

if not error_logger.handlers:
    error_logger.addHandler(error_handler)


# ---------------- DATABASE CONNECTION ----------------

def get_connection():
    return mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )


# ---------------- FILE READER ----------------

def read_data_file(file_path, extension):
    """Read supported formats and return a pandas DataFrame."""

    if extension == ".csv":
        df = pd.read_csv(
            file_path,
            dtype=object,
            keep_default_na=False
        )

    elif extension == ".tsv":
        df = pd.read_csv(
            file_path,
            sep="\t",
            dtype=object,
            keep_default_na=False
        )

    elif extension in {".xlsx", ".xls"}:
        df = pd.read_excel(
            file_path,
            sheet_name=0,
            dtype=object
        )

    elif extension == ".json":
        with open(file_path, "r", encoding="utf-8-sig") as file:
            content = json.load(file)

        if isinstance(content, list):
            df = pd.DataFrame(content)
        elif isinstance(content, dict):
            # Supports a single record or a column-oriented JSON object.
            if all(not isinstance(value, (dict, list))
                   for value in content.values()):
                df = pd.DataFrame([content])
            else:
                df = pd.DataFrame(content)
        else:
            raise ValueError(
                "JSON must contain an object or an array of records."
            )

    else:
        raise ValueError("Unsupported data file format.")

    # Normalize header names without changing their spelling.
    df.columns = [str(column).strip() for column in df.columns]

    if len(df.columns) == 0:
        raise ValueError("The file has no column headers.")

    if any(not column for column in df.columns):
        raise ValueError("Column headers cannot be empty.")

    if len(set(df.columns)) != len(df.columns):
        raise ValueError("Duplicate column headers were found.")

    return df


# ---------------- VALUE CONVERSION ----------------

def convert_value(value):
    """Convert pandas/Python values into MySQL-compatible values."""

    if value is None:
        return None

    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False)

    try:
        if pd.isna(value):
            return None
    except (TypeError, ValueError):
        pass

    if isinstance(value, pd.Timestamp):
        return value.to_pydatetime()

    if isinstance(value, (datetime, date)):
        return value

    if hasattr(value, "item"):
        value = value.item()

    if isinstance(value, str) and value.strip() == "":
        return None

    return value


# ---------------- ERROR COLUMN DETECTION ----------------

def identify_column(message, columns):
    """Best-effort attempt to identify a column mentioned in an error."""

    for column in columns:
        if re.search(
            rf"(?<!\w){re.escape(column)}(?!\w)",
            message,
            re.IGNORECASE
        ):
            return column

    return ""


# ---------------- RESULT TEMPLATE ----------------

def make_result(filename, table_name=""):
    return {
        "file": filename,
        "table": table_name,
        "status": "Failed",
        "total": 0,
        "inserted": 0,
        "failed": 0,
        "errors": [],
        "message": ""
    }


# ---------------- IMPORT ONE FILE ----------------

def import_file(connection, uploaded_file):
    original_name = uploaded_file.filename or "unnamed"
    filename = secure_filename(original_name)
    extension = Path(filename).suffix.lower()
    table_name = Path(filename).stem

    result = make_result(filename, table_name)

    if not filename or extension not in ALLOWED_EXTENSIONS:
        result["message"] = (
            "Unsupported file format. Use CSV, TSV, XLSX, XLS or JSON."
        )
        error_logger.error("%s: %s", filename, result["message"])
        return result

    # Restrict identifiers to safe, simple MySQL table names.
    if not re.fullmatch(r"[A-Za-z0-9_]+", table_name):
        result["message"] = (
            "The filename must contain only letters, numbers and underscores."
        )
        error_logger.error("%s: %s", filename, result["message"])
        return result

    temporary_path = None
    cursor = None

    try:
        # Save the upload temporarily so each supported reader can open it.
        import tempfile

        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=extension
        ) as temp_file:
            uploaded_file.save(temp_file)
            temporary_path = temp_file.name

        # Read the file before attempting row insertion.
        df = read_data_file(temporary_path, extension)
        result["total"] = len(df)

        # Check that the target table exists in the selected database.
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT TABLE_NAME
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = %s
              AND LOWER(TABLE_NAME) = LOWER(%s)
            """,
            (DB_NAME, table_name)
        )
        table_info = cursor.fetchone()

        if not table_info:
            result["message"] = (
                f"Table '{table_name}' does not exist in database '{DB_NAME}'."
            )
            result["failed"] = result["total"]
            error_logger.error("%s: %s", filename, result["message"])
            return result

        # Use the actual table name returned by MySQL.
        table_name = table_info["TABLE_NAME"]
        result["table"] = table_name

        cursor.execute(
            """
            SELECT COLUMN_NAME
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
            ORDER BY ORDINAL_POSITION
            """,
            (DB_NAME, table_name)
        )
        table_columns = [row["COLUMN_NAME"] for row in cursor.fetchall()]

        # Match headers to the actual database column names.
        actual_by_lower = {
            column.lower(): column for column in table_columns
        }

        mapped_columns = []
        unknown_columns = []

        for column in df.columns:
            actual_column = actual_by_lower.get(column.lower())
            if actual_column is None:
                unknown_columns.append(column)
            else:
                mapped_columns.append(actual_column)

        if unknown_columns:
            result["failed"] = result["total"]
            result["message"] = (
                "Unknown column(s): " + ", ".join(unknown_columns)
            )
            result["errors"].append({
                "row": "-",
                "column": ", ".join(unknown_columns),
                "message": result["message"]
            })
            error_logger.error("%s: %s", filename, result["message"])
            return result

        if len(df) == 0:
            result["status"] = "Success"
            result["message"] = "The file contains headers but no data rows."
            logging.info(
                "%s -> %s: no data rows",
                filename, table_name
            )
            return result

        # Build INSERT using validated table and column identifiers.
        column_sql = ", ".join(
            f"`{column}`" for column in mapped_columns
        )
        placeholders = ", ".join(["%s"] * len(mapped_columns))

        insert_sql = (
            f"INSERT INTO `{table_name}` ({column_sql}) "
            f"VALUES ({placeholders})"
        )

        # Insert each row separately so individual errors can be reported.
        for index, row in df.iterrows():
            csv_row_number = index + 2

            values = tuple(
                convert_value(row[column])
                for column in df.columns
            )

            row_cursor = connection.cursor()

            try:
                row_cursor.execute(insert_sql, values)
                connection.commit()
                result["inserted"] += 1

            except mysql.connector.Error as error:
                connection.rollback()
                message = str(error)

                result["failed"] += 1
                result["errors"].append({
                    "row": csv_row_number,
                    "column": identify_column(
                        message, mapped_columns
                    ),
                    "message": message
                })

                error_logger.error(
                    "%s | Table: %s | Row: %s | Error: %s",
                    filename, table_name, csv_row_number, message
                )

            except Exception as error:
                connection.rollback()
                message = str(error)

                result["failed"] += 1
                result["errors"].append({
                    "row": csv_row_number,
                    "column": "",
                    "message": message
                })

                error_logger.error(
                    "%s | Table: %s | Row: %s | Error: %s",
                    filename, table_name, csv_row_number, message
                )

            finally:
                row_cursor.close()

        if result["failed"] == 0:
            result["status"] = "Success"
            result["message"] = "All rows were inserted successfully."
            logging.info(
                "%s -> %s | Inserted: %s",
                filename, table_name, result["inserted"]
            )

        elif result["inserted"] > 0:
            result["status"] = "Partial Success"
            result["message"] = (
                "Some rows were inserted; others failed."
            )

        else:
            result["status"] = "Failed"
            result["message"] = "No rows were inserted successfully."

        return result

    except Exception as error:
        result["message"] = str(error)

        if result["total"] > 0 and result["inserted"] == 0:
            result["failed"] = result["total"]

        error_logger.error(
            "%s | Table: %s | File error: %s",
            filename, table_name, error
        )
        return result

    finally:
        if cursor is not None:
            cursor.close()

        if temporary_path and os.path.exists(temporary_path):
            os.remove(temporary_path)


# ---------------- WEB PAGES ----------------

@app.route("/")
def index():
    return render_template("index.html")


@app.route("/upload", methods=["POST"])
def upload():
    files = request.files.getlist("files")

    if not files or all(not file.filename for file in files):
        return jsonify({
            "error": "Please select at least one data file.",
            "results": []
        }), 400

    connection = None
    results = []

    try:
        connection = get_connection()

        for uploaded_file in files:
            if not uploaded_file.filename:
                continue

            result = import_file(connection, uploaded_file)
            results.append(result)

    except mysql.connector.Error as error:
        error_logger.error("Database connection error: %s", error)

        for uploaded_file in files:
            if uploaded_file.filename:
                result = make_result(
                    secure_filename(uploaded_file.filename)
                )
                result["message"] = (
                    "Database connection failed. Check app.py settings. "
                    + str(error)
                )
                results.append(result)

    finally:
        if connection is not None and connection.is_connected():
            connection.close()

    return jsonify({"results": results})


@app.errorhandler(413)
def file_too_large(error):
    return jsonify({
        "error": "The total upload size exceeds the 50 MB limit."
    }), 413


if __name__ == "__main__":
    app.run(debug=True)
