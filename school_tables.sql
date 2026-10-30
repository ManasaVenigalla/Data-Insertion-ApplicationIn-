use school;
CREATE TABLE roles (
    role_id INT PRIMARY KEY auto_increment,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE permissions (
    permission_id INT PRIMARY KEY auto_increment,
    permission_key VARCHAR(100) NOT NULL UNIQUE,
    module_name VARCHAR(100) NOT NULL
);


CREATE TABLE users (
    user_id INT PRIMARY KEY auto_increment,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role_id INT NOT NULL REFERENCES roles(role_id),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE user_sessions (
    session_id VARCHAR(255) PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL
);

CREATE TABLE audit_logs (
    log_id BIGINT PRIMARY KEY auto_increment,
    user_id INT REFERENCES users(user_id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id INT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


CREATE TABLE branches (
    branch_id INT primary KEY auto_increment,
    branch_name VARCHAR(150) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    address TEXT NOT NULL,
    tax_number VARCHAR(50)
);

CREATE TABLE academic_years (
    academic_year_id INT PRIMARY KEY auto_increment,
    display_name VARCHAR(50) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE NOT NULL,
    CONSTRAINT chk_academic_dates CHECK (end_date > start_date)
);

CREATE TABLE classes (
    class_id INT PRIMARY KEY auto_increment,
    class_name VARCHAR(100) NOT NULL unique,
    branch_id INT unique NOT NULL REFERENCES branches(branch_id)
);

CREATE TABLE sections (
    section_id INT PRIMARY KEY auto_increment,
    class_id INT NOT NULL REFERENCES classes(class_id),
    section_name VARCHAR(50) unique NOT NULL,
    room_number VARCHAR(50),
    capacity INT DEFAULT 40 NOT NULL
);


CREATE TABLE user_profiles (
    profile_id bigint PRIMARY KEY auto_increment,
    user_id INT NOT NULL UNIQUE REFERENCES users(user_id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(150),
    address TEXT,
    pin_code VARCHAR(20),
    mother_name VARCHAR(150),
    gender VARCHAR(20),
    date_of_birth DATE
);

CREATE TABLE staff_details (
    staff_id INT PRIMARY KEY auto_increment,
    user_id INT NOT NULL UNIQUE REFERENCES users(user_id),
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    designation VARCHAR(100) NOT NULL,
    joining_date DATE NOT NULL,
    qualification VARCHAR(150)
);

CREATE TABLE student_details (
    student_id varchar(50) PRIMARY KEY,
    user_id INT NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    id_number VARCHAR(50) NOT NULL UNIQUE,
    parent_user_id INT REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE TABLE student_enrollments (
    enrollment_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL unique REFERENCES student_details(student_id),
    section_id INT NOT NULL REFERENCES sections(section_id),
    academic_year_id INT NOT NULL REFERENCES academic_years(academic_year_id),
    roll_number INT NOT NULL,
    status VARCHAR(30) DEFAULT 'Active' NOT NULL
);


CREATE TABLE subjects (
    subject_id INT primary KEY auto_increment,
    subject_name VARCHAR(100) NOT NULL,
    subject_code VARCHAR(30) unique NOT NULL,
    branch_id INT NOT NULL unique REFERENCES branches(branch_id)
);

CREATE TABLE class_subjects (
    class_subject_id INT PRIMARY KEY auto_increment,
    class_id INT NOT NULL unique REFERENCES classes(class_id),
    subject_id INT NOT NULL unique REFERENCES subjects(subject_id)
);

CREATE TABLE subject_assignments (
    assignment_id INT PRIMARY KEY auto_increment,
    section_id INT NOT NULL unique REFERENCES sections(section_id),
    subject_id INT NOT NULL unique REFERENCES subjects(subject_id),
    staff_id INT NOT NULL REFERENCES staff_details(staff_id),
    academic_year_id INT NOT NULL unique REFERENCES academic_years(academic_year_id)
);

CREATE TABLE timetables (
    timetable_id INT PRIMARY KEY auto_increment,
    section_id INT NOT NULL unique REFERENCES sections(section_id),
    subject_id INT NOT NULL unique REFERENCES subjects(subject_id),
    staff_id INT NOT NULL REFERENCES staff_details(staff_id),
    day_of_week VARCHAR(15) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CONSTRAINT chk_timetable_time CHECK (end_time > start_time)
);



CREATE TABLE student_attendance (
    attendance_id BIGINT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL unique REFERENCES student_details(student_id),
    section_id INT NOT NULL REFERENCES sections(section_id),
    date DATE unique NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Present', 'Absent', 'Late')),
    remarks VARCHAR(255),
    marked_by_staff_id INT REFERENCES staff_details(staff_id)
);

CREATE TABLE staff_attendance (
    staff_attendance_id INT primary KEY auto_increment,
    staff_id INT NOT NULL unique REFERENCES staff_details(staff_id),
    date DATE unique NOT NULL,
    check_in TIME,
    check_out TIME,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Present', 'Absent', 'Half_Day'))
);



CREATE TABLE exam_types (
    exam_type_id INT PRIMARY KEY auto_increment,
    exam_type_name VARCHAR(100) NOT NULL,
    branch_id INT NOT NULL REFERENCES branches(branch_id)
);

CREATE TABLE exam_schedules (
    exam_schedule_id INT PRIMARY KEY,
    exam_type_id INT NOT NULL REFERENCES exam_types(exam_type_id) ON DELETE CASCADE,
    section_id INT NOT NULL REFERENCES sections(section_id) ON DELETE CASCADE,
    subject_id INT NOT NULL REFERENCES subjects(subject_id) ON DELETE CASCADE,
    exam_date DATE NOT NULL,
    start_time TIME NOT NULL,
    max_marks NUMERIC(6, 2) NOT NULL,
    passing_marks NUMERIC(6, 2) NOT NULL
);

CREATE TABLE student_marks (
    mark_id BIGINT PRIMARY KEY auto_increment,
    exam_schedule_id INT NOT NULL unique REFERENCES exam_schedules(exam_schedule_id),
    student_id INT NOT NULL unique REFERENCES student_details(student_id),
    marks_obtained NUMERIC(6, 2),
    is_absent BOOLEAN DEFAULT FALSE NOT NULL,
    recorded_by INT REFERENCES staff_details(staff_id)
);

CREATE TABLE grading_systems (
    grade_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    grade_letter VARCHAR(10) NOT NULL,
    min_percentage NUMERIC(5, 2) NOT NULL,
    max_percentage NUMERIC(5, 2) NOT NULL
);

CREATE TABLE teacher_reviews (
    review_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    staff_id INT NOT NULL REFERENCES staff_details(staff_id),
    academic_year_id INT NOT NULL REFERENCES academic_years(academic_year_id),
    review_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);



CREATE TABLE fee_categories (
    fee_category_id bigint PRIMARY KEY auto_increment,
    category_name VARCHAR(100) NOT NULL,
    branch_id INT NOT NULL REFERENCES branches(branch_id)
);

CREATE TABLE fee_structures (
    fee_structure_id INT PRIMARY KEY auto_increment,
    fee_category_id INT NOT NULL REFERENCES fee_categories(fee_category_id),
    class_id INT NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    academic_year_id INT NOT NULL REFERENCES academic_years(academic_year_id),
    amount NUMERIC(12, 2) NOT NULL,
    due_date DATE NOT NULL
);

CREATE TABLE student_fee_allocations (
    allocation_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL unique REFERENCES student_details(student_id) ON DELETE CASCADE,
    fee_structure_id INT NOT NULL unique REFERENCES fee_structures(fee_structure_id),
    discount_amount NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    net_amount_due NUMERIC(12, 2) NOT NULL
);

CREATE TABLE fee_payments (
    payment_id INT PRIMARY KEY auto_increment,
    allocation_id INT NOT NULL REFERENCES student_fee_allocations(allocation_id),
    amount_paid NUMERIC(12, 2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    payment_mode VARCHAR(30) NOT NULL CHECK (payment_mode IN ('Cash', 'Card', 'Bank_Transfer', 'Online')),
    transaction_reference VARCHAR(100),
    received_by INT REFERENCES users(user_id)
);


CREATE TABLE salary_contracts (
    contract_id INT PRIMARY KEY auto_increment,
    staff_id INT NOT NULL UNIQUE REFERENCES staff_details(staff_id),
    base_salary NUMERIC(12, 2) NOT NULL,
    allowances NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    deductions NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    effective_date DATE NOT NULL
);

CREATE TABLE monthly_payrolls (
    payroll_id INT PRIMARY KEY auto_increment,
    staff_id INT NOT NULL unique REFERENCES staff_details(staff_id),
    pay_period_month INT NOT NULL unique CHECK (pay_period_month BETWEEN 1 AND 12),
    pay_period_year INT unique NOT NULL,
    gross_salary NUMERIC(12, 2) NOT NULL,
    net_salary NUMERIC(12, 2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'Generated' NOT NULL CHECK (payment_status IN ('Generated', 'Approved', 'Paid')),
    payment_date DATE
);


CREATE TABLE inventory_categories (
    category_id INT PRIMARY KEY auto_increment,
    category_name VARCHAR(100) NOT NULL,
    branch_id INT NOT NULL REFERENCES branches(branch_id)
);

CREATE TABLE inventory_items (
    item_id INT PRIMARY KEY auto_increment,
    category_id INT NOT NULL REFERENCES inventory_categories(category_id),
    item_name VARCHAR(150) NOT NULL,
    sku_code VARCHAR(50) NOT NULL UNIQUE,
    total_quantity INT DEFAULT 0 NOT NULL,
    available_quantity INT DEFAULT 0 NOT NULL,
    CONSTRAINT chk_inventory_qty CHECK (available_quantity <= total_quantity)
);

CREATE TABLE inventory_transactions (
    transaction_id INT PRIMARY KEY auto_increment,
    item_id INT NOT NULL REFERENCES inventory_items(item_id),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('Purchase', 'Issue', 'Dispose')),
    quantity INT NOT NULL,
    issued_to_user_id INT REFERENCES users(user_id),
    action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);



CREATE TABLE branch_expenses (
    expense_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL unique REFERENCES branches(branch_id),
    expense_type VARCHAR(30) NOT NULL CHECK (expense_type IN ('Rent', 'Utility', 'Maintenance', 'Other')),
    amount NUMERIC(12, 2) NOT NULL,
    payment_date DATE NOT NULL,
    vendor_name VARCHAR(150),
    invoice_document_url VARCHAR(255)
);

CREATE TABLE tax_records (
    tax_record_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    assessment_period VARCHAR(50) NOT NULL,
    taxable_income NUMERIC(14, 2) NOT NULL,
    tax_amount_due NUMERIC(12, 2) NOT NULL,
    payment_status VARCHAR(30) DEFAULT 'Pending' NOT NULL
);

CREATE TABLE holidays (
    holiday_id INT PRIMARY KEY auto_increment,
    branch_id INT REFERENCES branches(branch_id),
    holiday_title VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_academic_closure BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT chk_holiday_dates CHECK (end_date >= start_date)
);

CREATE TABLE daily_financial_ledger (
    ledger_id BIGINT PRIMARY KEY,
    branch_id INT NOT NULL unique REFERENCES branches(branch_id) ON DELETE CASCADE,
    log_date DATE unique NOT NULL,
    total_fee_collected NUMERIC(14, 2) DEFAULT 0.00 NOT NULL,
    total_salaries_paid NUMERIC(14, 2) DEFAULT 0.00 NOT NULL,
    total_expenses_paid NUMERIC(14, 2) DEFAULT 0.00 NOT NULL,
    net_profit_loss NUMERIC(14, 2) NOT NULL
);


CREATE TABLE email_sms_gateways (
    gateway_id INT PRIMARY KEY auto_increment,
    gateway_name VARCHAR(100) NOT NULL,
    gateway_type VARCHAR(20) NOT NULL CHECK (gateway_type IN ('SMS', 'Email', 'Push')),
    api_key VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE NOT NULL
);


CREATE TABLE password_resets (
    reset_id INT PRIMARY KEY auto_increment,
    user_id INT NOT NULL REFERENCES users(user_id),
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE NOT NULL
);



CREATE TABLE file_uploads (
    file_id INT PRIMARY KEY auto_increment,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    file_size_bytes BIGINT,
    uploaded_by INT REFERENCES users(user_id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE lesson_plans (
    lesson_plan_id INT PRIMARY KEY,
    subject_assignment_id INT NOT NULL REFERENCES subject_assignments(assignment_id),
    topic_title VARCHAR(200) NOT NULL,
    estimated_hours INT DEFAULT 1 NOT NULL,
    status VARCHAR(20) DEFAULT 'Planned' NOT NULL CHECK (status IN ('Planned', 'In_Progress', 'Completed'))
);

CREATE TABLE assignments (
    assignment_id INT PRIMARY KEY auto_increment,
    subject_assignment_id INT NOT NULL REFERENCES subject_assignments(assignment_id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    max_marks NUMERIC(6, 2) NOT NULL,
    due_date TIMESTAMP  NOT NULL
);

CREATE TABLE assignment_submissions (
    submission_id BIGINT PRIMARY KEY auto_increment,
    assignment_id INT NOT NULL unique REFERENCES assignments(assignment_id),
    student_id varchar(50) NOT NULL unique REFERENCES student_details(student_id),
    submission_text TEXT,
    file_url VARCHAR(255),
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    marks_awarded NUMERIC(6, 2),
    feedback TEXT
);

CREATE TABLE library_books (
    book_id INT PRIMARY KEY auto_increment,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(150) NOT NULL,
    isbn VARCHAR(50) NOT NULL UNIQUE,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    status VARCHAR(20) DEFAULT 'Available' NOT NULL CHECK (status IN ('Available', 'Issued', 'Lost'))
);

CREATE TABLE library_issues (
    issue_id INT PRIMARY KEY auto_increment,
    book_id INT NOT NULL REFERENCES library_books(book_id),
    user_id INT NOT NULL REFERENCES users(user_id),
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    due_date DATE NOT NULL,
    returned_at TIMESTAMP,
    fine_amount NUMERIC(8, 2) DEFAULT 0.00 NOT NULL
);

CREATE TABLE late_fee_policies (
    policy_id INT PRIMARY KEY auto_increment,
    fee_structure_id INT NOT NULL REFERENCES fee_structures(fee_structure_id),
    grace_period_days INT DEFAULT 0 NOT NULL,
    fine_type VARCHAR(30) NOT NULL CHECK (fine_type IN ('Flat_Per_Day', 'Fixed_One_Time')),
    fine_amount NUMERIC(10, 2) NOT NULL
);

CREATE TABLE student_fines_ledger (
    fine_ledger_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    reason VARCHAR(255) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Unpaid' NOT NULL CHECK (status IN ('Unpaid', 'Paid')),
    payment_id INT REFERENCES fee_payments(payment_id)
);


CREATE TABLE job_openings (
    job_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    title VARCHAR(150) NOT NULL,
    department VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'Open' NOT NULL CHECK (status IN ('Open', 'Closed'))
);

CREATE TABLE job_applications (
    application_id INT PRIMARY KEY auto_increment,
    job_id INT NOT NULL REFERENCES job_openings(job_id),
    applicant_name VARCHAR(150) NOT NULL,
    resume_url VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'Applied' NOT NULL CHECK (status IN ('Applied', 'Interviewing', 'Offered', 'Rejected'))
);


CREATE TABLE staff_performance_appraisals (
    appraisal_id INT PRIMARY KEY auto_increment,
    staff_id INT NOT NULL REFERENCES staff_details(staff_id),
    reviewer_user_id INT REFERENCES users(user_id),
    review_period VARCHAR(50) NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments TEXT
);


CREATE TABLE inventory_suppliers (
    supplier_id INT PRIMARY KEY auto_increment,
    supplier_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(150),
    address TEXT
);

CREATE TABLE purchase_orders (
    po_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    supplier_id INT NOT NULL REFERENCES inventory_suppliers(supplier_id),
    order_date DATE NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Draft' NOT NULL CHECK (status IN ('Draft', 'Ordered', 'Received', 'Cancelled'))
);

CREATE TABLE purchase_order_items (
    po_item_id INT PRIMARY KEY auto_increment,
    po_id INT NOT NULL REFERENCES purchase_orders(po_id),
    item_name VARCHAR(150) NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL
);


CREATE TABLE exam_halls (
    hall_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    hall_name VARCHAR(100) NOT NULL,
    seating_capacity INT NOT NULL
);

CREATE TABLE exam_seating_allocations (
    seating_id BIGINT PRIMARY KEY auto_increment,
    exam_schedule_id INT NOT NULL unique REFERENCES exam_schedules(exam_schedule_id),
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    hall_id INT NOT NULL unique REFERENCES exam_halls(hall_id),
    seat_number VARCHAR(20) unique NOT NULL
);

CREATE TABLE exam_invigilators (
    invigilator_id INT PRIMARY KEY auto_increment,
    exam_schedule_id INT NOT NULL unique REFERENCES exam_schedules(exam_schedule_id),
    staff_id INT NOT NULL unique REFERENCES staff_details(staff_id)
);

CREATE TABLE exam_malpractice_logs (
    incident_id INT PRIMARY KEY auto_increment,
    exam_schedule_id INT NOT NULL REFERENCES exam_schedules(exam_schedule_id),
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    reported_by_staff_id INT REFERENCES staff_details(staff_id),
    incident_details TEXT NOT NULL,
    action_taken VARCHAR(150)
);

CREATE TABLE visitor_logs (
    visitor_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    visitor_name VARCHAR(150) NOT NULL,
    purpose VARCHAR(200) NOT NULL,
    check_in TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    check_out TIMESTAMP
);

CREATE TABLE student_medical_logs (
    medical_log_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    blood_group VARCHAR(10),
    issue TEXT,
    emergency_contact_name VARCHAR(150) NOT NULL,
    emergency_contact_phone VARCHAR(20) NOT NULL
);


CREATE TABLE transport_vehicles (
    vehicle_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    license_plate VARCHAR(30) NOT NULL UNIQUE,
    vehicle_model VARCHAR(100),
    seating_capacity INT NOT NULL,
    insurance_expiry DATE,
    status VARCHAR(20) DEFAULT 'Active' NOT NULL CHECK (status IN ('Active', 'Maintenance', 'Retired'))
);

CREATE TABLE transport_routes (
    route_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    route_name VARCHAR(100) NOT NULL,
    start_location VARCHAR(150) NOT NULL,
    end_location VARCHAR(150) NOT NULL
);

CREATE TABLE transport_stops (
    stop_id INT PRIMARY KEY auto_increment,
    route_id INT NOT NULL REFERENCES transport_routes(route_id),
    stop_name VARCHAR(150) NOT NULL,
    sequence_number INT NOT NULL,
    estimated_pickup_time TIME NOT NULL
);

CREATE TABLE vehicle_assignments (
    assignment_id INT PRIMARY KEY auto_increment,
    vehicle_id INT NOT NULL REFERENCES transport_vehicles(vehicle_id),
    route_id INT NOT NULL REFERENCES transport_routes(route_id),
    driver_staff_id INT NOT NULL REFERENCES staff_details(staff_id)
);

CREATE TABLE student_transport_registrations (
    registration_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    stop_id INT NOT NULL REFERENCES transport_stops(stop_id),
    fare_amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Active' NOT NULL CHECK (status IN ('Active', 'Cancelled'))
);


CREATE TABLE hostel_buildings (
    building_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    building_name VARCHAR(100) NOT NULL,
    gender_type VARCHAR(20) NOT NULL CHECK (gender_type IN ('Boys', 'Girls', 'Co-Ed')),
    warden_staff_id INT REFERENCES staff_details(staff_id)
);

CREATE TABLE hostel_rooms (
    room_id INT PRIMARY KEY auto_increment,
    building_id INT NOT NULL REFERENCES hostel_buildings(building_id),
    room_number VARCHAR(30) NOT NULL,
    room_type VARCHAR(30) NOT NULL CHECK (room_type IN ('Single', 'Shared_Double', 'Dormitory')),
    max_occupants INT DEFAULT 1 NOT NULL,
    fee_per_year NUMERIC(10, 2) NOT NULL
);
drop table hostel_rooms;
CREATE TABLE hostel_allocations (
    allocation_id INT PRIMARY KEY auto_increment,
    room_id INT NOT NULL REFERENCES hostel_rooms(room_id),
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    check_in_date DATE NOT NULL,
    check_out_date DATE,
    academic_year_id INT NOT NULL REFERENCES academic_years(academic_year_id)
);
drop table hostel_allocations;

CREATE TABLE hostel_attendance (
    hostel_attendance_id BIGINT PRIMARY KEY auto_increment,
    allocation_id INT NOT NULL REFERENCES hostel_allocations(allocation_id),
    date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Present', 'Absent', 'Leave')),
    marked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);


CREATE TABLE alumni_profiles (
    alumni_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL UNIQUE REFERENCES student_details(student_id),
    graduation_year INT NOT NULL,
    current_company VARCHAR(150),
    current_position VARCHAR(100),
    linkedin_url VARCHAR(255)
);


CREATE TABLE higher_studies_logs (
    log_id INT PRIMARY KEY auto_increment,
    alumni_id INT NOT NULL REFERENCES alumni_profiles(alumni_id),
    university_name VARCHAR(150) NOT NULL,
    degree_pursued VARCHAR(100) NOT NULL,
    admission_year INT NOT NULL
);

CREATE TABLE alumni_events (
   event_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    event_title VARCHAR(150) NOT NULL,
    event_date TIMESTAMP NOT NULL,
    location VARCHAR(200) NOT NULL
);


CREATE TABLE school_clubs (
    club_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    club_name VARCHAR(100) NOT NULL,
    mentor_staff_id INT REFERENCES staff_details(staff_id)
);

CREATE TABLE club_memberships (
    membership_id INT PRIMARY KEY auto_increment,
    club_id INT NOT NULL unique REFERENCES school_clubs(club_id),
    student_id varchar(50) NOT NULL unique REFERENCES student_details(student_id),
    joined_date DATE,
    role_in_club VARCHAR(50) DEFAULT 'Member' NOT NULL
);

CREATE TABLE sports_inventory (
    sports_item_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    item_name VARCHAR(150) NOT NULL,
    quantity_owned INT DEFAULT 0 NOT NULL,
    quantity_usable INT DEFAULT 0 NOT NULL
);

CREATE TABLE event_bookings (
    booking_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL REFERENCES branches(branch_id),
    facility_name VARCHAR(150) NOT NULL,
    purpose VARCHAR(200) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    booked_by_user_id INT REFERENCES users(user_id),
    CONSTRAINT chk_booking_time CHECK (end_time > start_time)
);

CREATE TABLE student_documents (
    document_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    document_type VARCHAR(100) NOT NULL,
    file_path_url VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    verification_status VARCHAR(20) DEFAULT 'Pending' NOT NULL CHECK (verification_status IN ('Pending', 'Verified', 'Rejected'))
);

CREATE TABLE id_card_issuances (
    issuance_id INT PRIMARY KEY auto_increment,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    issued_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Active' NOT NULL CHECK (status IN ('Active', 'Lost', 'Deactivated'))
);


CREATE TABLE software_licenses (
    license_id INT PRIMARY KEY auto_increment,
    software_name VARCHAR(150) NOT NULL,
    license_key VARCHAR(255) NOT NULL,
    purchase_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    cost NUMERIC(10, 2) NOT NULL
);


CREATE TABLE monthly_branch_revenue_summaries (
    summary_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL unique REFERENCES branches(branch_id),
    year INT unique NOT NULL,
    month INT unique NOT NULL CHECK (month BETWEEN 1 AND 12),
    gross_revenue NUMERIC(14, 2) NOT NULL,
    tax_deductions NUMERIC(12, 2) NOT NULL,
    net_savings NUMERIC(14, 2) NOT NULL
);

CREATE TABLE student_retention_metrics (
    metric_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL unique REFERENCES branches(branch_id),
    academic_year_id INT NOT NULL unique REFERENCES academic_years(academic_year_id),
    total_enrolled INT DEFAULT 0 NOT NULL,
    total_dropped_out INT DEFAULT 0 NOT NULL,
    total_graduated INT DEFAULT 0 NOT NULL
);

CREATE TABLE academic_performance_caches (
    cache_id INT PRIMARY KEY auto_increment,
    section_id INT unique NOT NULL REFERENCES sections(section_id),
    exam_type_id INT unique NOT NULL REFERENCES exam_types(exam_type_id),
    class_average_percentage NUMERIC(5, 2) NOT NULL,
    highest_score NUMERIC(6, 2) NOT NULL,
    fail_count INT DEFAULT 0 NOT NULL
);


CREATE TABLE parent_teacher_meetings (
    ptm_id INT PRIMARY KEY auto_increment,
    academic_year_id INT NOT NULL REFERENCES academic_years(academic_year_id),
    meeting_date DATE NOT NULL,
    description VARCHAR(255) NOT NULL
);

CREATE TABLE ptm_slots (
    slot_id INT PRIMARY KEY auto_increment,
    ptm_id INT NOT NULL REFERENCES parent_teacher_meetings(ptm_id),
    staff_id INT NOT NULL REFERENCES staff_details(staff_id),
    student_id varchar(50) REFERENCES student_details(student_id),
    time_slot TIME NOT NULL,
    status VARCHAR(20) DEFAULT 'Available' NOT NULL CHECK (status IN ('Available', 'Booked', 'Completed'))
);

CREATE TABLE disciplinary_incidents (
    incident_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    reported_by_staff_id INT REFERENCES staff_details(staff_id),
    incident_date DATE NOT NULL,
    description TEXT NOT NULL,
    action_taken VARCHAR(200)
);

CREATE TABLE gate_pass_logs (
    pass_id INT PRIMARY KEY auto_increment,
    student_id varchar(50) NOT NULL REFERENCES student_details(student_id),
    approved_by_user_id INT REFERENCES users(user_id),
    reason VARCHAR(255) NOT NULL,
    departure_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expected_return_time TIMESTAMP 
);

CREATE TABLE staff_exit_logs (
    exit_id INT PRIMARY KEY auto_increment,
    staff_id INT NOT NULL REFERENCES staff_details(staff_id),
    resignation_date DATE NOT NULL,
    notice_period_days INT DEFAULT 30 NOT NULL,
    proposed_relieving_date DATE NOT NULL,
    actual_relieving_date DATE,
    exit_type VARCHAR(30) NOT NULL CHECK (exit_type IN ('Resignation', 'Termination', 'Retirement', 'Contract_End')),
    primary_reason VARCHAR(100) NOT NULL,
    detailed_reason TEXT,
    approval_status VARCHAR(20) DEFAULT 'Pending' NOT NULL CHECK (approval_status IN ('Pending', 'Approved', 'Rejected')),
    approved_by_user_id INT REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE staff_fnf_settlements (
    fnf_id INT PRIMARY KEY auto_increment,
    exit_id INT NOT NULL UNIQUE REFERENCES staff_exit_logs(exit_id),
    pending_salary NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    leave_encashment NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    gratuity_amount NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    deductions NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    net_settlement_amount NUMERIC(12, 2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'Pending' NOT NULL CHECK (payment_status IN ('Pending', 'Approved', 'Paid')),
    settled_date DATE
);

CREATE TABLE staff_attrition_metrics (
    metric_id INT PRIMARY KEY auto_increment,
    branch_id INT NOT NULL unique REFERENCES branches(branch_id),
    year INT unique NOT NULL,
    month INT NOT NULL unique CHECK (month BETWEEN 1 AND 12),
    total_active_staff INT NOT NULL,
    total_joined INT DEFAULT 0 NOT NULL,
    total_left INT DEFAULT 0 NOT NULL
);

select * from branches;

-- USE school;

-- SET FOREIGN_KEY_CHECKS = 0;

-- DELIMITER $$

-- DROP PROCEDURE IF EXISTS clear_school_data$$

-- CREATE PROCEDURE clear_school_data()
-- BEGIN
--     DECLARE finished INT DEFAULT 0;
--     DECLARE tbl VARCHAR(255);

--     DECLARE table_cursor CURSOR FOR
--         SELECT table_name
--         FROM information_schema.tables
--         WHERE table_schema = 'school'
--           AND table_type = 'BASE TABLE';

--     DECLARE CONTINUE HANDLER FOR NOT FOUND
--         SET finished = 1;

--     OPEN table_cursor;

--     delete_loop: LOOP
--         FETCH table_cursor INTO tbl;

--         IF finished = 1 THEN
--             LEAVE delete_loop;
--         END IF;

--         SET @sql = CONCAT(
--             'DELETE FROM `school`.`',
--             REPLACE(tbl, '`', '``'),
--             '`'
--         );

--         PREPARE stmt FROM @sql;
--         EXECUTE stmt;
--         DEALLOCATE PREPARE stmt;
--     END LOOP;

--     CLOSE table_cursor;
-- END$$

-- DELIMITER ;

-- CALL clear_school_data();

-- DROP PROCEDURE IF EXISTS clear_school_data;

-- SET FOREIGN_KEY_CHECKS = 1;

-- use school;

-- SET SQL_SAFE_UPDATES = 0;
-- SET FOREIGN_KEY_CHECKS = 0;

-- CALL clear_school_data();

-- SET FOREIGN_KEY_CHECKS = 1;
-- SET SQL_SAFE_UPDATES = 1;

SELECT * FROM student_details;
SELECT * FROM exam_seating_allocations;

