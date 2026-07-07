# Green Acres Realty - Estate Management System (EMS)

Database Security assignment (CT069-3-3). This is a redesign of Green Acres Realty's EMS with proper access control, encryption, masking, auditing, and triggers.

## Team

| Name | Department |
|---|---|
| Izzah Zulkafli | Property Management Development |
| Sehneel Ansari | Client Portal Development |
| Sehneel Ansari | Analytics |
| Imran Amir | Database Administration |
| Lim Jia Hui | Agent Operations Development |

## What's in the script

- 5 department roles/logins, each only able to access data through views and stored procedures (no direct table access for developer roles)
- Password hashing (salted SHA2_256) with create/verify procedures
- Column-level encryption (AES-256) for Client/Agent PII
- Transparent Data Encryption (TDE) on the whole database
- Dynamic Data Masking for roles that shouldn't see raw PII (e.g. Analytics)
- Row-Level Security on Transactions
- Full/Differential/Log backups + certificate backups + a tested restore
- Server auditing and database auditing
- Triggers: 4 for auditing changes, 2 for business rules (auto-update property status, block maintenance requests on sold properties), 1 logon trigger
- CHECK constraints and password policy enforcement


## How to run

1. Open the script in SSMS
2. Update the file paths marked `>>> CHANGE ME` (backups and audit folders) to folders that exist on your machine
3. Run top to bottom, in order - later sections depend on earlier ones
4. Section 19 has test blocks for each department's access - run them separately to see it working

## Notes

- Run this against a fresh database. If you already have one with these table/view names, rename or drop it first.
- Passwords in the script are for coursework testing only.
- The server audit, server audit specification, logon trigger, and LoginAudit table are server-level, not per-database - if you've already run this once on the same server, those specific CREATE statements will error since they already exist. Just skip them.


## Documentation
https://1drv.ms/w/c/21354877929028ce/IQBJY2phBub5TJgJ7L2cqoz9AVBzHO4PRT95ct4CUMYkMqQ?e=K4ECxP
