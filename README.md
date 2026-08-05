# Green Acres Realty – Estate Management System (EMS)

Database Security assignment for CT069-3-3. This project redesigns Green Acres Realty’s original Estate Management System by introducing role-based access control, hashing, encryption, masking, auditing, recovery controls and operational security triggers.

## Departmental Accounts and Roles

The SQL implementation contains the following departmental login identities:

| Name                     | Assigned Role                   |
| ------------------------ | ------------------------------- |
| Izzah Zulkafli           | Property Management Development |
| Sehneel Ansari           | Client Portal Development       |
| Sehneel Ansari           | Analytics                       |
| Imran Amir               | Database Administration         |
| Lim Jia Hui              | Agent Operations Development    |
| `security_auditor_login` | Independent Security Auditor    |

The Security Auditor account is a separate read-only oversight role. It can examine approved audit evidence but cannot modify audit records or directly access operational PII.

## Files

### `Implementation_Group_19.sql`

Contains the complete database creation and security implementation in one SQL file, including all tables, views, procedures, roles, permissions, encryption objects, auditing, triggers, backups and documentation queries.

### `DBS_TestCases_Group_19.sql`

Contains all consolidated test cases and DML/verification queries used to test the completed implementation.

The implementation and test cases must remain as two separate SQL files. Do not divide either file into multiple smaller SQL scripts.

## Security Features Implemented

* Six database roles:

  * `PropertyMgmtDev`
  * `ClientPortalDev`
  * `AnalyticsTeam`
  * `DBAdminRole`
  * `AgentOpsDev`
  * `SecurityAuditor`
* Five departmental SQL logins plus an independent Security Auditor login
* Controlled access through ten views and thirteen stored procedures
* Explicit `DENY` permissions preventing developer roles from bypassing approved views and procedures
* Least-privilege and separation-of-duties design
* SQL login password policy and expiration enforcement
* Application-user password hashing using:

  * Random 32-byte salt
  * `SHA2_512`
  * Controlled account-creation and login-verification procedures
  * Five-attempt account lockout
  * DBA-controlled account recovery
* Client-email normalisation and `SHA2_256` hashing for duplicate detection
* Unique filtered index preventing duplicate normalised client emails
* AES-256 cell-level encryption for client and agent PII
* Dynamic Data Masking for client and agent contact information
* `UNMASK` permission restricted to `DBAdminRole`
* Transparent Data Encryption for database files and backups
* Fifteen SQL Server sensitivity classifications covering PII, financial and authentication data
* Row-Level Security on `Transactions`
* Full, differential and transaction-log backups
* Backup of the EMS database master key
* Backup of the `master` database master key
* Backup of the PII and TDE certificates and their private keys
* A tested restoration to `GreenAcresEMS_Final_RestoreTest`
* SQL Server Audit and Database Audit Specification
* Database-object change monitoring
* Server-level login history using `master.dbo.LoginAudit`
* Five full-CRUD AuditLog triggers covering:

  * `Properties`
  * `Clients`
  * `Agents`
  * `Transactions`
  * `MaintenanceRequests`
* Sensitive-value redaction in general audit summaries
* Append-only protection for `AuditLog`
* Agent commission history tracking
* Two operational triggers:

  * Automatically update a property’s status after a transaction
  * Prevent maintenance requests for sold properties
* One server-level logon trigger
* CHECK constraints, foreign keys and supporting indexes
* Parameterised stored procedures providing SQL-injection resistance
* Documentation and security-coverage queries
* A final submission backup

## Requirements Before Running

Create the following empty folders:

```text
C:\GreenAcresBackups\
C:\GreenAcresAudits\
```

The SQL Server service account must have **Modify/Write** permission for both folders.

For a default SQL Server instance, the service account is commonly:

```text
NT SERVICE\MSSQLSERVER
```

Confirm the actual service account in **SQL Server Configuration Manager** or Windows Services before assigning permissions.

## How to Run the Implementation

1. Open `Implementation_Group_19.sql` in SQL Server Management Studio.
2. Connect using an account with `sysadmin` permission.
3. Confirm that the query is connected to the intended SQL Server instance.
4. Ensure that `GreenAcresEMS_Final` does not already exist.
5. Ensure the backup and audit folders exist and have the required permissions.
6. Select **Query → Results To → Results to Text** (`Ctrl + T`).
7. Execute the entire implementation once without highlighting individual sections.
8. Save the complete Results-to-Text output and review it for unexpected errors beginning with `Msg`.
9. Do not rerun the implementation after it succeeds.
10. Open a new query and switch to **Results to Grid** (`Ctrl + D`).
11. Run only the final read-only verification query.
12. Capture the verification grids as report evidence.

In short:

* Full implementation run → **Results to Text**
* Final verification and report screenshots → **Results to Grid**
* Never rerun the implementation just to change the output format.

final read-only verification query to confirm:
   * Database exists
   * Server Audit is active
   * Logon trigger is enabled
   * Nine database triggers are active
   * Database Audit Specification is active
   * Fifteen columns are classified
   * TDE is active
   * Final backup exists

Do not execute the implementation file again after it has completed successfully.

## How to Run the Test Cases

1. Run the implementation successfully first.
2. Open `DBS_TestCases_Group_19.sql`.
3. Select **Query → Results To → Results to Text**.
4. Execute the complete test file without highlighting individual tests.
5. Review every reported result.
6. Permission-denied, append-only and constraint-conflict messages are intentional when their corresponding negative test reports `PASS`.
7. Save the final Results-to-Text output as supporting evidence for the report and demonstration.

The final test suite is repeatable, but it should only be run against the completed final implementation—not against a database containing objects from an older script.

## Important Fresh-Build Notes

* Always run the implementation against a fresh `GreenAcresEMS_Final` database.
* Do not run the final implementation over a database created by a previous version of the script.
* An existing database may contain incompatible tables, procedures, triggers, users, logins or audit objects.
* If the first output says that the database or objects already exist, stop the execution and clean the old coursework build before trying again.
* Do not ignore or skip “already exists” errors. Continuing after those errors can produce a mixed and unreliable database.
* Preserve any important old data or backup files before removing an earlier build.
* Existing backup or certificate files should be moved to a separate old-files folder before a fresh run.
* Passwords and encryption-key passwords stored in the script are for coursework demonstration only. A production deployment would store secrets outside the SQL script using an approved secrets-management solution.
* If TDE is unavailable on the installed SQL Server edition, the script reports a controlled fallback message; cell-level PII encryption remains available.
* The number of LoginAudit and AuditLog records may increase whenever SSMS reconnects or the test suite is repeated. These changing values are normal.

## Submission Files

Based on the lecturer’s clarification, submit:

* `Report_Group_19.pdf`
* `Implementation_Group_19.sql`
* `DBS_TestCases_Group_19.sql`
* Video recording only if the group is not presenting physically

The report should contain selected test outputs as evidence, but the complete raw output does not need to be pasted into the documentation.

## Documentation

[Green Acres EMS Group Documentation](https://1drv.ms/w/c/21354877929028ce/IQBJY2phBub5TJgJ7L2cqoz9AVBzHO4PRT95ct4CUMYkMqQ?e=K4ECxP)
