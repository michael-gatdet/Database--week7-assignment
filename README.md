# Database Week 7 Assignment

## Overview
This assignment demonstrates PostgreSQL auditing, recursive queries, database version control with Flyway, and least-privilege database security.

## Files
- `Answers.sql` — consolidated SQL reference for the assignment and final verification queries.
- `sql/V1__core_tables.sql` — creates the students table.
- `sql/V2__audit_log.sql` — creates the audit log, trigger function, and trigger.
- `sql/V3__categories.sql` — creates and populates the category hierarchy.
- `evidence/verification-results.txt` — summary of the successful checks performed.

## Environment
- PostgreSQL 18.6
- Flyway OSS 13.12.1
- Database used for migrations: `bootcamp_migrations`

## How to run the migrations
From PowerShell, change to this project folder and configure Flyway:

```powershell
$env:FLYWAY_URL = "jdbc:postgresql://localhost:5432/bootcamp_migrations"
$env:FLYWAY_USER = "postgres"
$env:FLYWAY_LOCATIONS = "filesystem:sql"
$secure = Read-Host "Enter PostgreSQL password" -AsSecureString
$env:FLYWAY_PASSWORD = [System.Net.NetworkCredential]::new("", $secure).Password
flyway migrate
Remove-Item Env:\FLYWAY_PASSWORD
```

The migration run completed successfully. The database history showed versions 1, 2, and 3 with `success = true`.

## Assignment tasks and results

### 1. Audit logging and triggers
Created an `audit_log` table and an `audit()` trigger function. The trigger records INSERT, UPDATE, and DELETE operations, including old/new row data, the database user, and the timestamp.

**Verification:** An INSERT made by the `api` account was recorded in `audit_log` with `op = INSERT`, `student_name = Bhan`, and `changed_by = api`.

### 2. Recursive category tree
Created a self-referencing `categories` table and used a recursive CTE to display parent and child categories.

Expected hierarchy:
```text
Electronics
   Computers
   Phones
     Laptops
```

### 3. Flyway installation
Installed Flyway OSS 13.12.1 and connected it to PostgreSQL 18.6.

### 4. Versioned migrations
Created and successfully applied:
- V1 — core tables
- V2 — audit log
- V3 — categories

### 5. Least-privilege security
Created `app_read` and `app_write` roles, plus login accounts `reader` and `api`.
- `reader` successfully ran SELECT.
- `reader` was denied UPDATE permission, as expected.
- `api` successfully inserted a student record.
- Default privileges were configured for future tables and sequences created by `postgres`.

## Final verification
The database contained these tables:
- `students`
- `audit_log`
- `categories`
- `flyway_schema_history`

The `students` table contained the test record:
- Student ID: 1
- First name: Bhan
- Last name: Gatdet
- Age: 25
- Course: Database

## Important security note
Database passwords are not included in this repository. Set passwords interactively with the PostgreSQL `\password` command.
