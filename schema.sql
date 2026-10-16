-- ============================================================
--  HOSPITAL MANAGEMENT SYSTEM - DBMS MINI PROJECT (MySQL 8+)
--  Run:  mysql -u root -p < hospital_management.sql
-- ============================================================

DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hospital_db;

-- ------------------------------------------------------------
-- 1. TABLES
-- ------------------------------------------------------------

CREATE TABLE department (
    dept_id     INT AUTO_INCREMENT PRIMARY KEY,
    dept_name   VARCHAR(60) NOT NULL UNIQUE,
    location    VARCHAR(60),
    phone       VARCHAR(15)
);

CREATE TABLE doctor (
    doctor_id       INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(40) NOT NULL,
    last_name       VARCHAR(40) NOT NULL,
    gender          ENUM('Male','Female','Other') NOT NULL,
    specialization  VARCHAR(80) NOT NULL,
    phone           VARCHAR(15) NOT NULL UNIQUE,
    email           VARCHAR(100) UNIQUE,
    consultation_fee DECIMAL(8,2) NOT NULL CHECK (consultation_fee >= 0),
    joining_date    DATE NOT NULL,
    dept_id         INT NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES department(dept_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE patient (
    patient_id      INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(40) NOT NULL,
    last_name       VARCHAR(40) NOT NULL,
    gender          ENUM('Male','Female','Other') NOT NULL,
    date_of_birth   DATE NOT NULL,
    blood_group     ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-'),
    phone           VARCHAR(15) NOT NULL,
    address         VARCHAR(150),
    registered_on   DATE NOT NULL DEFAULT (CURRENT_DATE)
);

CREATE TABLE appointment (
    appointment_id   INT AUTO_INCREMENT PRIMARY KEY,
    patient_id       INT NOT NULL,
    doctor_id        INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    reason           VARCHAR(200),
    status           ENUM('Scheduled','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id)  REFERENCES doctor(doctor_id)   ON DELETE CASCADE,
    UNIQUE (doctor_id, appointment_date, appointment_time)   -- no double booking
);

CREATE TABLE room (
    room_id        INT AUTO_INCREMENT PRIMARY KEY,
    room_number    VARCHAR(10) NOT NULL UNIQUE,
    room_type      ENUM('General','Semi-Private','Private','ICU') NOT NULL,
    charge_per_day DECIMAL(8,2) NOT NULL CHECK (charge_per_day >= 0),
    is_available   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE admission (
    admission_id    INT AUTO_INCREMENT PRIMARY KEY,
    patient_id      INT NOT NULL,
    room_id         INT NOT NULL,
    doctor_id       INT NOT NULL,
    admit_date      DATE NOT NULL,
    discharge_date  DATE NULL,
    diagnosis       VARCHAR(200),
    FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id)    REFERENCES room(room_id),
    FOREIGN KEY (doctor_id)  REFERENCES doctor(doctor_id),
    CHECK (discharge_date IS NULL OR discharge_date >= admit_date)
);

CREATE TABLE medicine (
    medicine_id   INT AUTO_INCREMENT PRIMARY KEY,
    medicine_name VARCHAR(80) NOT NULL UNIQUE,
    manufacturer  VARCHAR(80),
    unit_price    DECIMAL(8,2) NOT NULL CHECK (unit_price >= 0),
    stock_qty     INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0)
);

CREATE TABLE prescription (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id  INT NOT NULL,
    medicine_id     INT NOT NULL,
    dosage          VARCHAR(60) NOT NULL,      -- e.g. '1-0-1 after food'
    duration_days   INT NOT NULL CHECK (duration_days > 0),
    quantity        INT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (appointment_id) REFERENCES appointment(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (medicine_id)    REFERENCES medicine(medicine_id)
);

CREATE TABLE billing (
    bill_id         INT AUTO_INCREMENT PRIMARY KEY,
    patient_id      INT NOT NULL,
    appointment_id  INT NULL,
    admission_id    INT NULL,
    consultation_charge DECIMAL(10,2) NOT NULL DEFAULT 0,
    room_charge         DECIMAL(10,2) NOT NULL DEFAULT 0,
    medicine_charge     DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount        DECIMAL(10,2) GENERATED ALWAYS AS
                        (consultation_charge + room_charge + medicine_charge) STORED,
    bill_date       DATE NOT NULL DEFAULT (CURRENT_DATE),
    payment_status  ENUM('Pending','Paid') NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (patient_id)     REFERENCES patient(patient_id)         ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointment(appointment_id) ON DELETE SET NULL,
    FOREIGN KEY (admission_id)   REFERENCES admission(admission_id)     ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 2. SAMPLE DATA
-- ------------------------------------------------------------

INSERT INTO department (dept_name, location, phone) VALUES
('Cardiology',  'Block A, Floor 2', '0240-111001'),
('Neurology',   'Block A, Floor 3', '0240-111002'),
('Orthopedics', 'Block B, Floor 1', '0240-111003'),
('Pediatrics',  'Block C, Floor 1', '0240-111004'),
('General Medicine', 'Block B, Floor 2', '0240-111005');

INSERT INTO doctor (first_name, last_name, gender, specialization, phone, email, consultation_fee, joining_date, dept_id) VALUES
('Rajesh',  'Deshmukh', 'Male',   'Cardiologist',      '9800000001', 'rajesh.d@hospital.com',  800.00, '2015-06-01', 1),
('Sneha',   'Kulkarni', 'Female', 'Neurologist',       '9800000002', 'sneha.k@hospital.com',   900.00, '2017-03-15', 2),
('Amit',    'Patil',    'Male',   'Orthopedic Surgeon','9800000003', 'amit.p@hospital.com',    700.00, '2018-08-20', 3),
('Priya',   'Joshi',    'Female', 'Pediatrician',      '9800000004', 'priya.j@hospital.com',   500.00, '2019-01-10', 4),
('Vikram',  'Shinde',   'Male',   'General Physician', '9800000005', 'vikram.s@hospital.com',  400.00, '2020-11-05', 5);

INSERT INTO patient (first_name, last_name, gender, date_of_birth, blood_group, phone, address, registered_on) VALUES
('Ankit',   'Sharma', 'Male',   '1990-04-12', 'B+',  '9900000001', 'Garkheda, Aurangabad',  '2026-01-10'),
('Pooja',   'More',   'Female', '1985-09-23', 'O+',  '9900000002', 'Cidco, Aurangabad',     '2026-02-14'),
('Rohan',   'Gaikwad','Male',   '2012-07-05', 'A+',  '9900000003', 'Nirala Bazar, Aurangabad','2026-03-02'),
('Meera',   'Jadhav', 'Female', '1962-12-30', 'AB+', '9900000004', 'Jalna Road, Aurangabad','2026-04-18'),
('Sandeep', 'Pawar',  'Male',   '1978-01-15', 'O-',  '9900000005', 'Waluj, Aurangabad',     '2026-05-21'),
('Kavita',  'Bhosale','Female', '1995-06-08', 'A-',  '9900000006', 'Harsul, Aurangabad',    '2026-06-30');

INSERT INTO appointment (patient_id, doctor_id, appointment_date, appointment_time, reason, status) VALUES
(1, 1, '2026-10-01', '10:00:00', 'Chest pain',           'Completed'),
(2, 2, '2026-10-02', '11:30:00', 'Recurring headaches',  'Completed'),
(3, 4, '2026-10-03', '09:30:00', 'Fever and cough',      'Completed'),
(4, 1, '2026-10-05', '12:00:00', 'Routine heart checkup','Completed'),
(5, 3, '2026-10-08', '15:00:00', 'Knee pain',            'Completed'),
(6, 5, '2026-10-14', '10:30:00', 'General checkup',      'Scheduled'),
(1, 5, '2026-10-15', '11:00:00', 'Follow-up',            'Scheduled'),
(2, 2, '2026-10-09', '16:00:00', 'MRI discussion',       'Cancelled');

INSERT INTO room (room_number, room_type, charge_per_day, is_available) VALUES
('G-101', 'General',      800.00,  TRUE),
('G-102', 'General',      800.00,  TRUE),
('S-201', 'Semi-Private', 1500.00, TRUE),
('P-301', 'Private',      2500.00, TRUE),
('ICU-1', 'ICU',          6000.00, FALSE);

INSERT INTO admission (patient_id, room_id, doctor_id, admit_date, discharge_date, diagnosis) VALUES
(4, 5, 1, '2026-10-05', NULL,         'Acute coronary syndrome'),
(5, 3, 3, '2026-10-08', '2026-10-12', 'Meniscus tear - arthroscopy');

INSERT INTO medicine (medicine_name, manufacturer, unit_price, stock_qty) VALUES
('Paracetamol 500mg', 'Cipla',        2.50,  500),
('Amoxicillin 250mg', 'Sun Pharma',   8.00,  300),
('Atorvastatin 10mg', 'Dr. Reddy''s', 12.00, 200),
('Aspirin 75mg',      'Bayer',        3.00,  400),
('Ibuprofen 400mg',   'Abbott',       4.50,  250),
('Gabapentin 300mg',  'Lupin',        15.00, 150);

INSERT INTO prescription (appointment_id, medicine_id, dosage, duration_days, quantity) VALUES
(1, 4, '1-0-0 after food', 30, 30),
(1, 3, '0-0-1 at night',   30, 30),
(2, 6, '1-0-1 after food', 15, 30),
(3, 1, '1-1-1 after food', 5,  15),
(3, 2, '1-0-1 after food', 5,  10),
(5, 5, '1-0-1 after food', 7,  14);

INSERT INTO billing (patient_id, appointment_id, admission_id, consultation_charge, room_charge, medicine_charge, bill_date, payment_status) VALUES
(1, 1, NULL, 800.00, 0.00,     450.00,  '2026-10-01', 'Paid'),
(2, 2, NULL, 900.00, 0.00,     450.00,  '2026-10-02', 'Paid'),
(3, 3, NULL, 500.00, 0.00,     117.50,  '2026-10-03', 'Paid'),
(5, 5, 2,    700.00, 6000.00,  63.00,   '2026-10-12', 'Pending');

-- ------------------------------------------------------------
-- 3. VIEWS
-- ------------------------------------------------------------

-- Doctors with their departments
CREATE VIEW v_doctor_details AS
SELECT d.doctor_id,
       CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS doctor_name,
       d.specialization, dep.dept_name, d.consultation_fee, d.phone
FROM doctor d
JOIN department dep ON d.dept_id = dep.dept_id;

-- Full appointment information
CREATE VIEW v_appointment_details AS
SELECT a.appointment_id,
       CONCAT(p.first_name, ' ', p.last_name)         AS patient_name,
       CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS doctor_name,
       d.specialization, a.appointment_date, a.appointment_time,
       a.reason, a.status
FROM appointment a
JOIN patient p ON a.patient_id = p.patient_id
JOIN doctor  d ON a.doctor_id  = d.doctor_id;

-- Patients currently admitted
CREATE VIEW v_current_admissions AS
SELECT ad.admission_id,
       CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
       r.room_number, r.room_type, ad.admit_date,
       DATEDIFF(CURRENT_DATE, ad.admit_date) + 1 AS days_admitted,
       ad.diagnosis
FROM admission ad
JOIN patient p ON ad.patient_id = p.patient_id
JOIN room    r ON ad.room_id    = r.room_id
WHERE ad.discharge_date IS NULL;

-- ------------------------------------------------------------
-- 4. STORED PROCEDURE, FUNCTION, TRIGGERS
-- ------------------------------------------------------------

DELIMITER $$

-- Function: patient age
CREATE FUNCTION fn_patient_age(p_id INT) RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE dob DATE;
    SELECT date_of_birth INTO dob FROM patient WHERE patient_id = p_id;
    RETURN TIMESTAMPDIFF(YEAR, dob, CURRENT_DATE);
END$$

-- Procedure: book an appointment safely
CREATE PROCEDURE sp_book_appointment(
    IN p_patient INT, IN p_doctor INT,
    IN p_date DATE,   IN p_time TIME, IN p_reason VARCHAR(200))
BEGIN
    IF EXISTS (SELECT 1 FROM appointment
               WHERE doctor_id = p_doctor AND appointment_date = p_date
                 AND appointment_time = p_time AND status <> 'Cancelled') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor already booked for this slot';
    ELSE
        INSERT INTO appointment (patient_id, doctor_id, appointment_date, appointment_time, reason)
        VALUES (p_patient, p_doctor, p_date, p_time, p_reason);
    END IF;
END$$

-- Procedure: discharge a patient and generate the bill
CREATE PROCEDURE sp_discharge_patient(IN p_admission INT, IN p_date DATE)
BEGIN
    DECLARE v_room INT;
    DECLARE v_patient INT;
    DECLARE v_admit DATE;
    DECLARE v_rate DECIMAL(8,2);

    SELECT room_id, patient_id, admit_date
      INTO v_room, v_patient, v_admit
      FROM admission WHERE admission_id = p_admission;

    SELECT charge_per_day INTO v_rate FROM room WHERE room_id = v_room;

    UPDATE admission SET discharge_date = p_date WHERE admission_id = p_admission;

    INSERT INTO billing (patient_id, admission_id, room_charge, bill_date)
    VALUES (v_patient, p_admission, v_rate * (DATEDIFF(p_date, v_admit) + 1), p_date);
END$$

-- Trigger: mark room occupied on admission
CREATE TRIGGER trg_admission_insert
AFTER INSERT ON admission FOR EACH ROW
BEGIN
    UPDATE room SET is_available = FALSE WHERE room_id = NEW.room_id;
END$$

-- Trigger: free room on discharge
CREATE TRIGGER trg_admission_update
AFTER UPDATE ON admission FOR EACH ROW
BEGIN
    IF OLD.discharge_date IS NULL AND NEW.discharge_date IS NOT NULL THEN
        UPDATE room SET is_available = TRUE WHERE room_id = NEW.room_id;
    END IF;
END$$

-- Trigger: reduce medicine stock on prescription
CREATE TRIGGER trg_prescription_insert
BEFORE INSERT ON prescription FOR EACH ROW
BEGIN
    DECLARE v_stock INT;
    SELECT stock_qty INTO v_stock FROM medicine WHERE medicine_id = NEW.medicine_id;
    IF v_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient medicine stock';
    END IF;
    UPDATE medicine SET stock_qty = stock_qty - NEW.quantity
    WHERE medicine_id = NEW.medicine_id;
END$$

DELIMITER ;
