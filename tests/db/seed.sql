-- Seed data for orgChart API tests
-- This file is automatically loaded when PostgreSQL container starts

-- Create test database schema
CREATE SCHEMA IF NOT EXISTS public;

-- Create test tables
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS jobs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    department_id INTEGER REFERENCES departments(id),
    salary_min INTEGER,
    salary_max INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS persons (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    job_id INTEGER REFERENCES jobs(id),
    manager_id INTEGER REFERENCES persons(id),
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    person_id INTEGER REFERENCES persons(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO departments (name, description) VALUES
    ('Engineering', 'Software development and technical operations'),
    ('Human Resources', 'Employee management and relations'),
    ('Sales', 'Business development and client relations'),
    ('Marketing', 'Brand management and promotion'),
    ('Finance', 'Financial planning and accounting');

INSERT INTO jobs (title, description, department_id, salary_min, salary_max) VALUES
    ('Software Engineer', 'Develop and maintain software applications', 1, 70000, 120000),
    ('Senior Software Engineer', 'Lead software development projects', 1, 100000, 160000),
    ('HR Manager', 'Manage human resources department', 2, 80000, 130000),
    ('Sales Representative', 'Sell products and services to clients', 3, 50000, 90000),
    ('Marketing Coordinator', 'Coordinate marketing campaigns', 4, 45000, 75000),
    ('Financial Analyst', 'Analyze financial data and trends', 5, 60000, 100000);

INSERT INTO persons (first_name, last_name, email, phone, job_id, manager_id, hire_date) VALUES
    ('John', 'Doe', 'john.doe@company.com', '555-1234', 2, NULL, '2020-01-15'),
    ('Jane', 'Smith', 'jane.smith@company.com', '555-5678', 1, 1, '2021-03-20'),
    ('Mike', 'Johnson', 'mike.johnson@company.com', '555-9012', 1, 1, '2021-06-10'),
    ('Sarah', 'Williams', 'sarah.williams@company.com', '555-3456', 3, NULL, '2020-11-05'),
    ('Tom', 'Brown', 'tom.brown@company.com', '555-7890', 4, NULL, '2022-02-14'),
    ('Lisa', 'Davis', 'lisa.davis@company.com', '555-2468', 5, NULL, '2021-09-30'),
    ('Bob', 'Wilson', 'bob.wilson@company.com', '555-1357', 6, NULL, '2022-05-18');

INSERT INTO users (username, email, password_hash, person_id) VALUES
    ('john.doe', 'john.doe@company.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGZfHRfJJP3YGb6', 1),
    ('jane.smith', 'jane.smith@company.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGZfHRfJJP3YGb6', 2),
    ('mike.johnson', 'mike.johnson@company.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGZfHRfJJP3YGb6', 3),
    ('sarah.williams', 'sarah.williams@company.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewGZfHRfJJP3YGb6', 4);

-- Create indexes for better performance
CREATE INDEX idx_persons_job_id ON persons(job_id);
CREATE INDEX idx_persons_manager_id ON persons(manager_id);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_jobs_department_id ON jobs(department_id);

-- Create views for common queries
CREATE VIEW employee_details AS
SELECT 
    p.id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone,
    j.title as job_title,
    d.name as department_name,
    m.first_name as manager_first_name,
    m.last_name as manager_last_name
FROM persons p
LEFT JOIN jobs j ON p.job_id = j.id
LEFT JOIN departments d ON j.department_id = d.id
LEFT JOIN persons m ON p.manager_id = m.id;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO orgchart_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO orgchart_user;

-- Display summary
SELECT 'Database setup complete' as status;
SELECT 'Departments: ' || COUNT(*) as departments_count FROM departments;
SELECT 'Jobs: ' || COUNT(*) as jobs_count FROM jobs;
SELECT 'Persons: ' || COUNT(*) as persons_count FROM persons;
SELECT 'Users: ' || COUNT(*) as users_count FROM users;
