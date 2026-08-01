/* =============================================================================
   DBS_TestCases_<Group_19>.sql
   Green Acres Realty EMS - Database Security Assignment - CT069-3-3

   Purpose: Compiled test cases proving each security control works as
   designed. Each test states: what is being tested, the SQL used, and the
   expected result. Run against the completed GreenAcresEMS_Final database
   (after running the full Implementation script).

   Structure: Tests are grouped by feature area, numbered TC-<area>-<n>.
   Sections marked [BEYOND BRIEF] go past the minimum requirement to also
   test edge cases and negative scenarios, not just the happy path.
   ============================================================================= */

USE GreenAcresEMS_Final;
GO


/* =============================================================================
   GROUP A: ROLE-BASED ACCESS CONTROL
   Every department should be able to use its own Views/Procedures, and be
   denied all direct table access.
   ============================================================================= */

-- TC-A1: Client Portal Development - View access
-- Expected: returns rows (basic client info, no PII)
REVERT;
EXECUTE AS USER = 'sehneel_ansari_login';
SELECT * FROM vw_ClientPortal_Clients;
REVERT;

-- TC-A2: Client Portal Development - decrypted PII via procedure
-- Expected: returns rows with real, readable ContactNumber/Email/Address
EXECUTE AS USER = 'sehneel_ansari_login';
EXEC sp_GetClientContactInfo;
REVERT;

-- TC-A3: Client Portal Development - controlled write via procedure
-- Expected: succeeds, inserts a new encrypted client record
EXECUTE AS USER = 'sehneel_ansari_login';
EXEC sp_RegisterNewClient
    @FullName = 'Test Case Client A3',
    @ContactNumber = '019-0000001',
    @Email = 'tc.a3@gmail.com',
    @Address = '1 Jalan Testing, Shah Alam';
REVERT;

-- TC-A4: Client Portal Development - direct table access
-- Expected: FAILS with permission denied (DENY on Clients table)
EXECUTE AS USER = 'sehneel_ansari_login';
SELECT * FROM Clients;
REVERT;

-- TC-A5: Property Management Development - View access
-- Expected: returns property listings with OpenMaintenanceRequests count
EXECUTE AS USER = 'izzah_zulkafli_login';
SELECT * FROM vw_PropertyMgmt_Properties;
REVERT;

-- TC-A6: Property Management Development - controlled write
-- Expected: succeeds, Property status changes to 'Rented'
EXECUTE AS USER = 'izzah_zulkafli_login';
EXEC sp_UpdatePropertyStatus @PropertyID = 3, @NewStatus = 'Rented';
REVERT;

-- TC-A7: Property Management Development - direct table access
-- Expected: FAILS with permission denied
EXECUTE AS USER = 'izzah_zulkafli_login';
SELECT * FROM Properties;
REVERT;

-- TC-A8: Analytics - masked view access
-- Expected: returns rows with ContactNumber/Email displayed as masked (XXX style)
EXECUTE AS USER = 'priya_suhuba_login';
SELECT * FROM vw_Analytics_ClientSummary;
REVERT;

-- TC-A9: Analytics - aggregate view (no PII)
-- Expected: returns real TotalTransactions/TotalSalesValue numbers, masked Email
EXECUTE AS USER = 'priya_suhuba_login';
SELECT * FROM vw_Analytics_AgentPerformance;
REVERT;

-- TC-A10: Analytics - direct table access
-- Expected: FAILS with permission denied
EXECUTE AS USER = 'priya_suhuba_login';
SELECT * FROM Clients;
REVERT;

-- TC-A11: Database Administration - full direct access
-- Expected: succeeds, returns REAL unmasked PII (UNMASK permission)
EXECUTE AS USER = 'imran_amir_login';
SELECT ClientID, FullName, ContactNumber, Email, Address FROM Clients;
REVERT;

-- TC-A12: Database Administration - Users table access, but hash stays unreadable
-- Expected: succeeds, PasswordHash column still shows binary, not plaintext
EXECUTE AS USER = 'imran_amir_login';
SELECT UserID, Username, PasswordHash FROM Users;
REVERT;

-- TC-A13: Agent Operations Development - View access
-- Expected: returns agent list with TotalTransactions counts
EXECUTE AS USER = 'limjiahui_login';
SELECT * FROM vw_AgentOps_Agents;
REVERT;

-- TC-A14: Agent Operations Development - decrypted PII via procedure
-- Expected: returns real ContactNumber/Email
EXECUTE AS USER = 'limjiahui_login';
EXEC sp_GetAgentContactInfo;
REVERT;

-- TC-A15: Agent Operations Development - direct table access
-- Expected: FAILS with permission denied
EXECUTE AS USER = 'limjiahui_login';
SELECT * FROM Agents;
REVERT;

-- TC-A16 [BEYOND BRIEF]: Cross-department boundary check
-- A dev role should ALSO be denied on tables that belong to OTHER departments,
-- not just their own. Expected: FAILS with permission denied.
EXECUTE AS USER = 'sehneel_ansari_login';   -- Client Portal Dev
SELECT * FROM Agents;                       -- not their table at all
REVERT;

-- TC-A17 [BEYOND BRIEF]: No DELETE anywhere for developer roles
-- Confirms no developer role can ever hard-delete data, protecting Availability.
-- Expected: 0 rows - no GRANT DELETE exists for any developer role.
SELECT dp.name AS RoleName, perm.state_desc, perm.permission_name
FROM sys.database_permissions perm
JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
WHERE dp.name IN ('PropertyMgmtDev','ClientPortalDev','AnalyticsTeam','AgentOpsDev')
  AND perm.permission_name = 'DELETE'
  AND perm.state_desc = 'GRANT';


/* =============================================================================
   GROUP B: PASSWORD HASHING
   ============================================================================= */

-- TC-B1: Password never stored as plaintext
-- Expected: PasswordHash column shows unreadable binary for every user
SELECT UserID, Username, PasswordHash FROM Users;

-- TC-B2: Correct password verifies successfully
-- Expected: @Result = 1
DECLARE @ResultCorrect BIT;
EXEC sp_VerifyAppUserLogin @Username = 'izzah.zulkafli', @PlaintextPassword = 'Izzah@2026!', @IsValid = @ResultCorrect OUTPUT;
SELECT 'TC-B2: Correct password' AS TestCase, @ResultCorrect AS Result;

-- TC-B3: Incorrect password fails verification
-- Expected: @Result = 0
DECLARE @ResultWrong BIT;
EXEC sp_VerifyAppUserLogin @Username = 'izzah.zulkafli', @PlaintextPassword = 'WrongPassword123', @IsValid = @ResultWrong OUTPUT;
SELECT 'TC-B3: Incorrect password' AS TestCase, @ResultWrong AS Result;

-- TC-B4 [BEYOND BRIEF]: Two users with the SAME password produce DIFFERENT hashes
-- Proves the random salt is genuinely working - identical passwords must not
-- be visually identifiable as identical in storage.
EXEC sp_CreateAppUser @Username = 'tc_saltcheck1', @PlaintextPassword = 'SamePassword123!', @DepartmentID = 1;
EXEC sp_CreateAppUser @Username = 'tc_saltcheck2', @PlaintextPassword = 'SamePassword123!', @DepartmentID = 1;
SELECT Username, PasswordHash FROM Users WHERE Username IN ('tc_saltcheck1','tc_saltcheck2');
-- Expected: the two PasswordHash values are DIFFERENT despite identical input password


/* =============================================================================
   GROUP C: COLUMN-LEVEL ENCRYPTION
   ============================================================================= */

-- TC-C1: Encrypted columns show ciphertext, not plaintext
-- Expected: ContactNumber_Enc/Email_Enc/Address_Enc show binary, unreadable
SELECT ClientID, FullName, ContactNumber_Enc, Email_Enc, Address_Enc FROM Clients;

-- TC-C2: Decryption recovers the original value correctly
-- Expected: Decrypted columns match the original plaintext exactly
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
SELECT
    ClientID, FullName,
    CONVERT(NVARCHAR(20), DECRYPTBYKEY(ContactNumber_Enc)) AS DecryptedContactNumber,
    ContactNumber AS OriginalContactNumber
FROM Clients;
CLOSE SYMMETRIC KEY PIIKey;

-- TC-C3 [BEYOND BRIEF]: Encryption at rest survives Transparent Data Encryption too
-- Expected: is_encrypted = 1, confirming TDE is active on top of column encryption
SELECT name, is_encrypted FROM sys.databases WHERE name = 'GreenAcresEMS_Final';


/* =============================================================================
   GROUP D: DYNAMIC DATA MASKING
   ============================================================================= */

-- TC-D1: Analytics sees masked PII
-- Expected: Email like 'sXXX@XXXX.com', ContactNumber partially hidden
REVERT;
EXECUTE AS USER = 'priya_suhuba_login';
SELECT ClientID, FullName, ContactNumber, Email, RegisteredDate FROM vw_Analytics_ClientSummary;
REVERT;

-- TC-D2: DBA sees real, unmasked PII (UNMASK permission)
-- Expected: real readable phone/email/address
EXECUTE AS USER = 'imran_amir_login';
SELECT ClientID, FullName, ContactNumber, Email, Address FROM Clients;
REVERT;

-- TC-D3 [BEYOND BRIEF]: Masking does not block aggregation/analysis
-- Expected: even though Email is masked, COUNT/SUM still return accurate,
-- real business figures - proves masking hides identity, not utility.
EXECUTE AS USER = 'priya_suhuba_login';
SELECT AgentID, Email, TotalTransactions, TotalSalesValue FROM vw_Analytics_AgentPerformance;
REVERT;


/* =============================================================================
   GROUP E: ROW-LEVEL SECURITY
   Note: DENY (Sections 9, 11) blocks most roles from Transactions before RLS
   is ever evaluated - DENY always takes precedence over RLS filtering. To
   isolate and prove RLS specifically works, we temporarily GRANT SELECT to
   a role NOT included in the RLS predicate function, confirming RLS still
   filters it to 0 rows even though the GRANT succeeded. This proves RLS acts
   as a genuine second layer of defense, independent of table-level DENY.
   ============================================================================= */

-- TC-E1: DBAdminRole (included in RLS predicate) sees Transaction rows
-- Expected: returns the real row count (10+)
REVERT;
EXECUTE AS USER = 'imran_amir_login';
SELECT COUNT(*) AS VisibleTransactionRows FROM Transactions;
REVERT;

-- TC-E2: Isolate RLS from DENY - temporarily grant a role NOT in the RLS
-- predicate, then confirm RLS alone filters it to 0 rows.
GRANT SELECT ON Transactions TO PropertyMgmtDev;
GO

EXECUTE AS USER = 'izzah_zulkafli_login';
SELECT COUNT(*) AS VisibleTransactionRows FROM Transactions;
-- Expected: 0 rows - proves RLS filters even when table-level access is granted
REVERT;

-- Revoke the temporary grant - not part of the actual production design,
-- PropertyMgmtDev should stay DENY'd on Transactions as originally built.
REVOKE SELECT ON Transactions FROM PropertyMgmtDev;
GO


/* =============================================================================
   GROUP F: TRIGGERS - AUDITING
   ============================================================================= */

-- TC-F1: Properties UPDATE is captured with before/after JSON
REVERT;
UPDATE Properties SET Status = 'Available' WHERE PropertyID = 8;
SELECT TOP 1 * FROM AuditLog WHERE TableName = 'Properties' ORDER BY ChangedDate DESC;

-- TC-F1b: Properties UPDATE with a genuine status change (cleaner before/after evidence)
-- Expected: OldValue shows "Status":"Available", NewValue shows "Status":"Rented"
UPDATE Properties SET Status = 'Rented' WHERE PropertyID = 8;
SELECT TOP 1 * FROM AuditLog WHERE TableName = 'Properties' ORDER BY ChangedDate DESC;

-- TC-F2: Clients INSERT is captured
EXEC sp_RegisterNewClient @FullName = 'Test Case Client F2', @ContactNumber = '019-1111111', @Email = 'tc.f2@gmail.com', @Address = '2 Jalan Test, KL';
SELECT TOP 1 * FROM AuditLog WHERE TableName = 'Clients' ORDER BY ChangedDate DESC;

-- TC-F3: Agents INSERT is captured
EXEC sp_RegisterNewAgent @FullName = 'Test Case Agent F3', @ContactNumber = '019-2222222', @Email = 'tc.f3@greenacres.com', @CommissionRate = 2.00;
SELECT TOP 1 * FROM AuditLog WHERE TableName = 'Agents' ORDER BY ChangedDate DESC;

-- TC-F4: Transactions INSERT is captured
EXEC sp_AddTransaction @PropertyID = 5, @ClientID = 6, @AgentID = 2, @TransactionType = 'Rent', @Amount = 2000;
SELECT TOP 1 * FROM AuditLog WHERE TableName = 'Transactions' ORDER BY ChangedDate DESC;


/* =============================================================================
   GROUP G: TRIGGERS - OPERATIONAL (BUSINESS RULES)
   ============================================================================= */

-- TC-G1: Sale transaction auto-updates Property status to 'Sold'
EXEC sp_AddTransaction @PropertyID = 5, @ClientID = 1, @AgentID = 3, @TransactionType = 'Sale', @Amount = 480000;
SELECT PropertyID, Status, ModifiedDate, ModifiedBy FROM Properties WHERE PropertyID = 5;
-- Expected: Status = 'Sold'

-- TC-G2: Maintenance request on a Sold property is BLOCKED
EXEC sp_AddMaintenanceRequest @PropertyID = 5, @RequestDetails = 'TC-G2: should be rejected';
-- Expected: custom error "Cannot add a maintenance request for a property that has already been Sold."

-- TC-G3 [BEYOND BRIEF]: Maintenance request on an Available property SUCCEEDS
-- Confirms the block is specific to Sold status, not a blanket failure.
EXEC sp_AddMaintenanceRequest @PropertyID = 3, @RequestDetails = 'TC-G3: should succeed, property still Available';
SELECT TOP 1 * FROM MaintenanceRequests WHERE PropertyID = 3 ORDER BY RequestDate DESC;

-- TC-G4 [BEYOND BRIEF]: Combined trigger interaction
-- A single Rent transaction should BOTH change status to 'Rented' (operational
-- trigger) AND create an AuditLog entry for the Transaction insert (auditing
-- trigger) AND an AuditLog entry for the resulting Property update, in one
-- action. Proves multiple triggers correctly co-exist on related tables.
EXEC sp_AddTransaction @PropertyID = 6, @ClientID = 2, @AgentID = 4, @TransactionType = 'Rent', @Amount = 1800;
SELECT PropertyID, Status FROM Properties WHERE PropertyID = 6;                       -- Expected: 'Rented'
SELECT * FROM AuditLog WHERE TableName IN ('Transactions','Properties') ORDER BY ChangedDate DESC;  -- Expected: 2 new rows


/* =============================================================================
   GROUP H: TRIGGER - LOGON (SERVER-LEVEL)
   ============================================================================= */

-- TC-H1: A new connection is logged
-- Expected: after opening a new SSMS query window/connection, a new row
-- appears here with the login name, timestamp, and host machine name.
SELECT TOP 20 * FROM master.dbo.LoginAudit ORDER BY LoginTime DESC;


/* =============================================================================
   GROUP I: SERVER & DATABASE AUDITING
   ============================================================================= */

-- TC-I1: A failed login attempt is captured
-- Precondition: open a new connection using SQL Server Authentication with
-- login 'izzah_zulkafli_login' and a deliberately WRONG password, then run:
SELECT event_time, action_id, succeeded, server_principal_name
FROM sys.fn_get_audit_file('C:\GreenAcresAudits\*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id = 'LGIF'
  AND server_principal_name NOT LIKE 'NT SERVICE%'
ORDER BY event_time DESC;
-- Expected: a row with succeeded = 0 for the attempted login
SELECT TOP 5 * FROM master.dbo.LoginAudit ORDER BY LoginTime DESC;


-- TC-I2: A SELECT on Clients is captured with the exact statement text
SELECT ClientID, FullName FROM Clients;
GO
SELECT event_time, server_principal_name, database_name, object_name, statement
FROM sys.fn_get_audit_file('C:\GreenAcresAudits\*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id = 'SL' AND object_name = 'Clients'
ORDER BY event_time DESC;


/* =============================================================================
   GROUP J: BACKUPS & RESTORE
   ============================================================================= */

-- TC-J1: Full, Differential, and Log backups exist
SELECT
    bs.database_name, bs.backup_start_date,
    CASE bs.type WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction Log' END AS BackupType
FROM msdb.dbo.backupset bs
WHERE bs.database_name = 'GreenAcresEMS_Final'
ORDER BY bs.backup_start_date DESC;

-- TC-J2 [BEYOND BRIEF]: Backup is genuinely restorable, not just a file on disk
-- (Run once, using a fresh test database name; clean up after confirming)
RESTORE DATABASE GreenAcresEMS_TestRestore
    FROM DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Full.bak'
    WITH
        MOVE 'GreenAcresEMS_Final'     TO 'C:\GreenAcresBackups\GreenAcresEMS_TestRestore.mdf',
        MOVE 'GreenAcresEMS_Final_log' TO 'C:\GreenAcresBackups\GreenAcresEMS_TestRestore_log.ldf',
        RECOVERY;
GO
USE GreenAcresEMS_TestRestore;
GO
SELECT COUNT(*) AS RestoredClientCount FROM Clients;   -- Expected: matches original row count
USE GreenAcresEMS_Final;
GO
USE master;
GO
DROP DATABASE GreenAcresEMS_TestRestore;
GO
USE GreenAcresEMS_Final;
GO

-- TC-J2b [BEYOND BRIEF]: Fresh backup reflecting current full dataset
-- Purpose: The earlier backup (Section 13) only captured 10 clients, since
-- it was taken before later test records were added. This creates a new
-- backup capturing the database's current, complete state (14 clients),
-- then restores it to prove the row count now matches exactly.
BACKUP DATABASE GreenAcresEMS_Final
    TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Latest.bak'
    WITH INIT, NAME = 'GreenAcresEMS_Final-Latest Backup';
GO


RESTORE DATABASE GreenAcresEMS_TestRestore2
    FROM DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Latest.bak'
    WITH
        MOVE 'GreenAcresEMS_Final'     TO 'C:\GreenAcresBackups\GreenAcresEMS_TestRestore2.mdf',
        MOVE 'GreenAcresEMS_Final_log' TO 'C:\GreenAcresBackups\GreenAcresEMS_TestRestore2_log.ldf',
        RECOVERY;
GO

USE GreenAcresEMS_TestRestore2;
GO
SELECT COUNT(*) AS RestoredClientCount FROM Clients;   -- Expected: 14

USE GreenAcresEMS_Final;
GO
USE master;
GO
DROP DATABASE GreenAcresEMS_TestRestore2;
GO
USE GreenAcresEMS_Final;
GO


/* =============================================================================
   GROUP K: DATA INTEGRITY (CHECK CONSTRAINTS) [BEYOND BRIEF]
   These go beyond the minimum brief requirement to prove the database
   engine itself rejects invalid data, independent of any application or
   procedure-level validation.
   ============================================================================= */

-- TC-K1: Negative property price is rejected
-- Expected: FAILS with a CHECK constraint violation error
INSERT INTO Properties (PropertyName, Address, City, State, Price, Status)
VALUES ('Invalid Price Test', '1 Jalan Test', 'KL', 'WP', -500, 'Available');

-- TC-K2: Invalid property status is rejected
-- Expected: FAILS - 'Unavailable' is not in the allowed list
INSERT INTO Properties (PropertyName, Address, City, State, Price, Status)
VALUES ('Invalid Status Test', '1 Jalan Test', 'KL', 'WP', 500000, 'Unavailable');

-- TC-K3: Commission rate outside 0-100 is rejected
-- Expected: FAILS - CommissionRate CHECK constraint violation
INSERT INTO Agents (FullName, ContactNumber, Email, CommissionRate)
VALUES ('Invalid Commission Test', '019-0000000', 'invalid@test.com', 150.00);

-- TC-K4: Invalid transaction type is rejected
-- Expected: FAILS - only 'Sale' or 'Rent' allowed
INSERT INTO Transactions (PropertyID, ClientID, AgentID, TransactionType, Amount)
VALUES (1, 1, 1, 'Lease', 1000);

-- TC-K5: Negative transaction amount is rejected
-- Expected: FAILS - CHECK (Amount >= 0)
INSERT INTO Transactions (PropertyID, ClientID, AgentID, TransactionType, Amount)
VALUES (1, 1, 1, 'Sale', -1000);


/* =============================================================================
   GROUP L: SQL INJECTION RESISTANCE [BEYOND BRIEF]
   Proves parameterized stored procedure inputs are treated strictly as
   data, never as executable SQL, regardless of what the caller supplies.
   ============================================================================= */

-- TC-L1: Attempted injection string is stored literally, not executed
-- Expected: succeeds, and the malicious-looking string is stored as plain
-- text in FullName - it does NOT drop any table or alter query behaviour.
EXEC sp_RegisterNewClient
    @FullName = N'Robert''); DROP TABLE Clients; --',
    @ContactNumber = '019-9999999',
    @Email = 'injection.test@gmail.com',
    @Address = '1 Jalan Injection Test';

SELECT ClientID, FullName FROM Clients WHERE Email = 'injection.test@gmail.com';
-- Expected: Clients table still exists and contains this literal string as a name


/* =============================================================================
   GROUP M: LEAST PRIVILEGE SELF-CHECK
   ============================================================================= */

-- TC-M1: Developer roles show mostly DENY, DBA shows mostly GRANT
-- Expected: PropertyMgmtDev/ClientPortalDev/AnalyticsTeam/AgentOpsDev have
-- DenyCount > GrantCount (or GrantCount limited to their own views/procs);
-- DBAdminRole has GrantCount much higher than DenyCount (0).
SELECT
    dp.name AS RoleName,
    SUM(CASE WHEN perm.state_desc = 'GRANT' THEN 1 ELSE 0 END) AS GrantCount,
    SUM(CASE WHEN perm.state_desc = 'DENY'  THEN 1 ELSE 0 END) AS DenyCount
FROM sys.database_permissions perm
JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
WHERE dp.type = 'R'
  AND dp.name IN ('PropertyMgmtDev','ClientPortalDev','AnalyticsTeam','DBAdminRole','AgentOpsDev')
GROUP BY dp.name
ORDER BY dp.name;

/* =============================================================================
   GROUP N: CLIENT EMAIL HASHING [BONUS]
   Purpose: Prove duplicate-email detection works correctly via hashing,
   including normalization (case and whitespace differences should still be
   detected as duplicates), and confirm genuinely new emails are unaffected.
   ============================================================================= */


-- TC-N1: Duplicate email is rejected
-- Expected: FAILS with custom error message
EXEC sp_RegisterNewClient
    @FullName = 'Duplicate Test',
    @ContactNumber = '019-8888888',
    @Email = 'leon.kennedy@gmail.com',
    @Address = '1 Jalan Duplicate Test';

-- TC-N2: Case/whitespace variation of an existing email is ALSO rejected
-- Expected: FAILS - proves normalization works
EXEC sp_RegisterNewClient
    @FullName = 'Duplicate Test 2',
    @ContactNumber = '019-7777777',
    @Email = '  LEON.KENNEDY@GMAIL.COM  ',
    @Address = '2 Jalan Duplicate Test';

-- TC-N3: A genuinely new email succeeds
-- Expected: succeeds normally
EXEC sp_RegisterNewClient
    @FullName = 'Genuine New Client',
    @ContactNumber = '019-6666666',
    @Email = 'genuinely.new@gmail.com',
    @Address = '3 Jalan New';

/* =============================================================================
   END OF TEST CASES
   Total: 16 groups (A-N), covering every required technique plus 10
   additional edge-case / negative / logical tests beyond the minimum brief.
   ============================================================================= */
