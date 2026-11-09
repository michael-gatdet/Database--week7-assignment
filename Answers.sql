-- DATABASE WEEK 7 ASSIGNMENT
-- PostgreSQL 18.6
-- Main reference script for the work completed during the lab.
-- IMPORTANT: The Flyway migration files are in the sql/ folder.
-- Run Flyway migrations on a fresh practice database; do not run this
-- complete script on top of a database where those migrations already ran.

-- =========================================================
-- TASK 1: AUDIT LOGGING AND TRIGGERS
-- =========================================================

CREATE TABLE IF NOT EXISTS students (
    student_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    age INT,
    course VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tbl TEXT,
    op TEXT,
    old_row JSONB,
    new_row JSONB,
    changed_by TEXT DEFAULT current_user,
    at TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION audit()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (tbl, op, old_row, new_row)
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit ON students;

CREATE TRIGGER trg_audit
AFTER INSERT OR UPDATE OR DELETE
ON students
FOR EACH ROW
EXECUTE FUNCTION audit();

-- Example tests (use suitable IDs in a fresh database):
-- INSERT INTO students VALUES (1, 'Kofi', 'Mensah', 22, 'Database');
-- UPDATE students SET first_name = 'Kofi M.' WHERE student_id = 1;
-- DELETE FROM students WHERE student_id = 1;

-- View audit history:
SELECT
    tbl,
    op,
    old_row,
    new_row,
    changed_by,
    at
FROM audit_log
ORDER BY at DESC;


-- =========================================================
-- TASK 2: RECURSIVE CATEGORY TREE
-- =========================================================

CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id INT REFERENCES categories(id)
);

-- The following sample data was used in the lab.
-- Run these inserts only once in a fresh database.
-- INSERT INTO categories (name, parent_id) VALUES
-- ('Electronics', NULL),
-- ('Computers', 1),
-- ('Laptops', 2),
-- ('Phones', 1);

WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, 0 AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.id, c.name, c.parent_id, t.depth + 1
    FROM categories c
    JOIN tree t ON c.parent_id = t.id
)
SELECT repeat('  ', depth) || name AS category_tree
FROM tree
ORDER BY depth, name;


-- =========================================================
-- TASK 3 AND 4: FLYWAY VERSIONED MIGRATIONS
-- =========================================================
-- The actual migration files are:
-- sql/V1__core_tables.sql
-- sql/V2__audit_log.sql
-- sql/V3__categories.sql
--
-- Flyway commands (run in PowerShell from the project folder):
-- flyway info
-- flyway migrate
--
-- The lab successfully applied versions 1, 2, and 3.


-- =========================================================
-- TASK 5: LEAST-PRIVILEGE SECURITY
-- =========================================================
-- These role commands were run by the database administrator.
-- They are shown here as the SQL record of the security setup.
-- CREATE ROLE app_read;
-- CREATE ROLE app_write;
-- CREATE ROLE api LOGIN IN ROLE app_write;
-- CREATE ROLE reader LOGIN IN ROLE app_read;
--
-- Set login passwords interactively in psql; never store passwords
-- in this assignment file:
-- \password api
-- \password reader

GRANT CONNECT ON DATABASE bootcamp_migrations TO app_read, app_write;
GRANT USAGE ON SCHEMA public TO app_read, app_write;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_read;
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public TO app_write;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public TO app_write;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT ON TABLES TO app_read;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_write;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT USAGE, SELECT ON SEQUENCES TO app_write;

-- Security tests performed:
-- 1. reader: SELECT from students succeeded.
-- 2. reader: UPDATE on students was denied (expected).
-- 3. api: INSERT into students succeeded.
-- 4. audit_log recorded the INSERT with changed_by = 'api'.


-- =========================================================
-- FINAL VERIFICATION QUERIES
-- =========================================================

-- Check Flyway migration history:
SELECT installed_rank, version, description, success
FROM flyway_schema_history
ORDER BY installed_rank;

-- List tables:
-- In psql, use: \dt

-- Check student records:
SELECT * FROM students;

-- Check the latest audit events:
SELECT
    tbl,
    op,
    new_row->>'first_name' AS student_name,
    changed_by,
    at
FROM audit_log
ORDER BY at DESC;
