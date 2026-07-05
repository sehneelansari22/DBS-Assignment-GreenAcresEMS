# DBS-Assignment-GreenAcresEMS
Database Security assignment - Estate Management System (EMS) migration for Green Acres Realty Sdn Bhd. Implements roles, views, stored procedures, encryption, masking, auditing, and triggers in SQL Server.

# Database Security Assignment — Green Acres Realty EMS
## Overview
This repository contains our group's implementation for migrating Green Acres Realty's Estate Management System (EMS) into a secure, role-based database architecture, as required by the assignment brief.

## Team Members
- Izzah Zulkafli — Property Management Development
- Sehneel Ansari — Client Portal Development
- Sehneel Ansari— Analytics
- Imran Amir — Database Administration
- Lim Jia Hui— Agent Operations Development

## What's Implemented
- 5 department-based Roles and Users
- Views and Stored Procedures enforcing least-privilege access per role
- Password Hashing (SHA-256)
- Column-level Encryption (AES-256) for Client/Agent PII
- Dynamic Data Masking
- Full, Differential, and Transaction Log Backups (with restore test)
- Server Auditing and Database Auditing
- Auditing and Operational Triggers

## Files
- `GreenAcresEMS_Full_Implementation.sql` — complete SQL script (schema, roles, security features, triggers, in order)
- `DBS_TestCases_<group number>.docx` — test cases and results
- `Report_<group number>.pdf` — full project documentation

## Note
Passwords used in this script are for demonstration/testing purposes only and should never be reused in a real production environment.
