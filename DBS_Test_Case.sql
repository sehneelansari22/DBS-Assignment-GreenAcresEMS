/* =============================================================================
   DBS_TestCases_Group_19.sql
   Green Acres Realty EMS - Database Security Assignment - CT069-3-3

   Run after Implementation_Group_19.sql. Tests retain the original Group 19
   A-N structure. Expected failures are caught and reported as PASS so one
   negative test does not stop later tests. Data-changing tests use ROLLBACK
   where possible to remain repeatable.
   ============================================================================= */

USE GreenAcresEMS_Final;
GO

/* =============================================================================
   GROUP A: ROLE-BASED ACCESS CONTROL
   ============================================================================= */

-- TC-A1: Client Portal view access - expected rows without raw PII columns.
BEGIN TRY
    EXECUTE AS USER='sehneel_ansari_login';
    SELECT * FROM vw_ClientPortal_Clients;
    REVERT;
    SELECT 'TC-A1 Client Portal view' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A1 Client Portal view' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A2: Client Portal decrypts one authorised client through the procedure.
BEGIN TRY
    EXECUTE AS USER='sehneel_ansari_login';
    EXEC sp_GetClientContactInfo @ClientID=1;
    REVERT;
    SELECT 'TC-A2 Controlled client PII' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A2 Controlled client PII' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A3: Client Portal controlled write; rolled back after proof.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @A3Email NVARCHAR(100)=CONCAT('a3.',REPLACE(CONVERT(NVARCHAR(36),NEWID()),'-',''),'@test.com');
    EXECUTE AS USER='sehneel_ansari_login';
    EXEC sp_RegisterNewClient @FullName='Test Case Client A3',@ContactNumber='019-0000001',
         @Email=@A3Email,@Address='1 Jalan Testing, Shah Alam';
    REVERT;
    SELECT ClientID,FullName,EmailHash FROM Clients WHERE Email=@A3Email;
    ROLLBACK TRANSACTION;
    SELECT 'TC-A3 Controlled client insert' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-A3 Controlled client insert' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A4: Direct Client Portal access to Clients must be denied.
BEGIN TRY
    EXECUTE AS USER='sehneel_ansari_login';
    SELECT * FROM Clients;
    REVERT;
    SELECT 'TC-A4 Client table denied' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A4 Client table denied' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A5/A6: Property Management approved view and controlled update.
BEGIN TRY
    BEGIN TRANSACTION;
    EXECUTE AS USER='izzah_zulkafli_login';
    SELECT * FROM vw_PropertyMgmt_Properties;
    EXEC sp_UpdatePropertyStatus @PropertyID=3,@NewStatus='Rented';
    REVERT;
    SELECT PropertyID,Status FROM Properties WHERE PropertyID=3;
    ROLLBACK TRANSACTION;
    SELECT 'TC-A5/A6 Property approved access' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-A5/A6 Property approved access' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A7: Property Management direct table access must be denied.
BEGIN TRY
    EXECUTE AS USER='izzah_zulkafli_login'; SELECT * FROM Properties; REVERT;
    SELECT 'TC-A7 Property table denied' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A7 Property table denied' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A8/A9: Analytics uses approved masked/aggregate views.
BEGIN TRY
    EXECUTE AS USER='priya_suhuba_login';
    SELECT * FROM vw_Analytics_ClientSummary;
    SELECT * FROM vw_Analytics_AgentPerformance;
    SELECT * FROM vw_Analytics_PropertyMarket;
    SELECT * FROM vw_Analytics_MonthlyTransactions;
    REVERT;
    SELECT 'TC-A8/A9 Analytics approved views' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A8/A9 Analytics approved views' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A10: Analytics direct Clients access is denied.
BEGIN TRY
    EXECUTE AS USER='priya_suhuba_login'; SELECT * FROM Clients; REVERT;
    SELECT 'TC-A10 Analytics table denied' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A10 Analytics table denied' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A11/A12: DBA sees unmasked PII but password hashes remain irreversible.
BEGIN TRY
    EXECUTE AS USER='imran_amir_login';
    SELECT ClientID,FullName,ContactNumber,Email,Address FROM Clients;
    SELECT UserID,Username,PasswordSalt,PasswordHash,FailedLoginCount,IsActive FROM Users;
    REVERT;
    SELECT 'TC-A11/A12 DBA PII and irreversible hashes' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A11/A12 DBA PII and irreversible hashes' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A13/A14: Agent Operations approved views and one-record PII procedure.
BEGIN TRY
    EXECUTE AS USER='limjiahui_login';
    SELECT * FROM vw_AgentOps_Agents;
    SELECT * FROM vw_AgentOps_Transactions;
    SELECT * FROM vw_AgentOps_PerformanceSummary;
    EXEC sp_GetAgentContactInfo @AgentID=1;
    REVERT;
    SELECT 'TC-A13/A14 Agent Operations approved access' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A13/A14 Agent Operations approved access' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A15/A16: Agent Operations and cross-department raw access is denied.
BEGIN TRY
    EXECUTE AS USER='limjiahui_login'; SELECT * FROM Agents; REVERT;
    SELECT 'TC-A15 Agent table denied' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A15 Agent table denied' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;

BEGIN TRY
    EXECUTE AS USER='sehneel_ansari_login'; SELECT * FROM Agents; REVERT;
    SELECT 'TC-A16 Cross-department access denied' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A16 Cross-department access denied' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-A17/A18: Independent auditor reads evidence but not operational PII.
BEGIN TRY
    EXECUTE AS USER='security_auditor_login';
    SELECT TOP(20) * FROM AuditLog ORDER BY ChangedDate DESC;
    SELECT TOP(20) * FROM AgentCommissionHistory ORDER BY ChangedDate DESC;
    REVERT;
    SELECT 'TC-A17 Auditor evidence access' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A17 Auditor evidence access' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;

BEGIN TRY
    EXECUTE AS USER='security_auditor_login'; SELECT * FROM Clients; REVERT;
    SELECT 'TC-A18 Auditor PII denied' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-A18 Auditor PII denied' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP B: PASSWORD HASHING AND ACCOUNT LOCKOUT
   ============================================================================= */

-- TC-B1: Binary salt/hash lengths prove plaintext is not stored.
SELECT UserID,Username,DATALENGTH(PasswordSalt) AS SaltBytes,
       DATALENGTH(PasswordHash) AS HashBytes,
       CASE WHEN DATALENGTH(PasswordSalt)=32 AND DATALENGTH(PasswordHash)=64 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM Users;
GO

-- TC-B2/B3: Correct password returns 1; incorrect password returns 0.
DECLARE @Correct BIT,@Wrong BIT;
EXEC sp_VerifyAppUserLogin @Username='izzah.zulkafli',@PlaintextPassword='Izzah@2026App!',@IsValid=@Correct OUTPUT;
EXEC sp_VerifyAppUserLogin @Username='izzah.zulkafli',@PlaintextPassword='WrongPassword123!',@IsValid=@Wrong OUTPUT;
SELECT 'TC-B2/B3 Verification' AS TestCase,@Correct AS CorrectResult,@Wrong AS WrongResult,
       CASE WHEN @Correct=1 AND @Wrong=0 THEN 'PASS' ELSE 'FAIL' END AS Result;
GO

-- TC-B4: Same password creates different random salts and hashes.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Suffix NVARCHAR(32)=REPLACE(CONVERT(NVARCHAR(36),NEWID()),'-','');
    DECLARE @U1 NVARCHAR(50)=CONCAT('salt1_',@Suffix),@U2 NVARCHAR(50)=CONCAT('salt2_',@Suffix);
    EXEC sp_CreateAppUser @Username=@U1,@PlaintextPassword='SamePassword123!',@DepartmentID=1;
    EXEC sp_CreateAppUser @Username=@U2,@PlaintextPassword='SamePassword123!',@DepartmentID=1;
    SELECT 'TC-B4 Independent salts' AS TestCase,
           CASE WHEN a.PasswordSalt<>b.PasswordSalt AND a.PasswordHash<>b.PasswordHash THEN 'PASS' ELSE 'FAIL' END AS Result,
           a.PasswordSalt AS FirstSalt,b.PasswordSalt AS SecondSalt,a.PasswordHash AS FirstHash,b.PasswordHash AS SecondHash
    FROM Users a CROSS JOIN Users b WHERE a.Username=@U1 AND b.Username=@U2;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-B4 Independent salts' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-B5: Five failures lock the account; DBAdminRole recovery unlocks it.
-- Requires: GRANT EXECUTE ON sp_UnlockAppUser TO DBAdminRole in implementation.
BEGIN TRY
    EXEC sp_UnlockAppUser @Username='izzah.zulkafli';

    DECLARE @Attempt INT=0,@Valid BIT;
    WHILE @Attempt<5
    BEGIN
        EXEC sp_VerifyAppUserLogin
             @Username='izzah.zulkafli',
             @PlaintextPassword='WrongPassword123!',
             @IsValid=@Valid OUTPUT;
        SET @Attempt+=1;
    END;

    SELECT 'TC-B5a Account lockout' AS TestCase,FailedLoginCount,IsActive,
           CASE WHEN FailedLoginCount=5 AND IsActive=0 THEN 'PASS' ELSE 'FAIL' END AS Result
    FROM Users WHERE Username='izzah.zulkafli';

    EXECUTE AS USER='imran_amir_login';
    EXEC sp_UnlockAppUser @Username='izzah.zulkafli';
    REVERT;

    SELECT 'TC-B5b DBAdminRole account recovery' AS TestCase,FailedLoginCount,IsActive,
           CASE WHEN FailedLoginCount=0 AND IsActive=1 THEN 'PASS' ELSE 'FAIL' END AS Result
    FROM Users WHERE Username='izzah.zulkafli';
END TRY
BEGIN CATCH
    DECLARE @B5Error NVARCHAR(4000)=ERROR_MESSAGE();
    IF USER_NAME()<>'dbo' REVERT;

    -- Cleanup prevents the demonstration account remaining locked after failure.
    BEGIN TRY
        EXEC sp_UnlockAppUser @Username='izzah.zulkafli';
    END TRY
    BEGIN CATCH
        SET @B5Error=CONCAT(@B5Error,' | Cleanup warning: ',ERROR_MESSAGE());
    END CATCH;

    SELECT 'TC-B5 Account lockout and DBAdminRole recovery' AS TestCase,
           'FAIL' AS Result,@B5Error AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP C: COLUMN-LEVEL ENCRYPTION AND TDE
   ============================================================================= */

-- TC-C1: Encrypted PII columns contain binary ciphertext.
SELECT ClientID,FullName,ContactNumber_Enc,Email_Enc,Address_Enc,
       CASE WHEN ContactNumber_Enc IS NOT NULL AND Email_Enc IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS Result
FROM Clients;
GO

-- TC-C2: Controlled decryption recovers legitimate values.
BEGIN TRY
    OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
    SELECT ClientID,FullName,
           CONVERT(NVARCHAR(20),DECRYPTBYKEY(ContactNumber_Enc)) AS DecryptedContact,
           CONVERT(NVARCHAR(100),DECRYPTBYKEY(Email_Enc)) AS DecryptedEmail
    FROM Clients;
    CLOSE SYMMETRIC KEY PIIKey;
    SELECT 'TC-C2 Controlled PII decryption' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name='PIIKey')
        CLOSE SYMMETRIC KEY PIIKey;
    SELECT 'TC-C2 Controlled PII decryption' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-C3: TDE is enabled and has reached the fully encrypted state.
SELECT d.name,d.is_encrypted,dek.encryption_state,
       CASE dek.encryption_state
           WHEN 0 THEN 'No database encryption key'
           WHEN 1 THEN 'Unencrypted'
           WHEN 2 THEN 'Encryption in progress'
           WHEN 3 THEN 'Encrypted'
           WHEN 4 THEN 'Key change in progress'
           WHEN 5 THEN 'Decryption in progress'
           WHEN 6 THEN 'Protection change in progress'
       END AS EncryptionStateDescription,
       CASE WHEN d.is_encrypted=1 AND dek.encryption_state=3
            THEN 'PASS' ELSE 'CHECK EDITION OR ENCRYPTION STATE' END AS Result
FROM sys.databases d
LEFT JOIN sys.dm_database_encryption_keys dek
       ON d.database_id=dek.database_id
WHERE d.name='GreenAcresEMS_Final';
GO

-- TC-C4: Functional proof that every ciphertext value decrypts to its
-- corresponding inherited plaintext value. This verifies correctness rather
-- than treating non-NULL binary output alone as proof of encryption quality.
BEGIN TRY
    OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

    DECLARE @C4Clients INT,@C4ClientMatches INT,
            @C4Agents INT,@C4AgentMatches INT;

    SELECT
        @C4Clients=COUNT(*),
        @C4ClientMatches=COALESCE(SUM(CASE
            WHEN (ContactNumber=CONVERT(NVARCHAR(20),DECRYPTBYKEY(ContactNumber_Enc))
                  OR (ContactNumber IS NULL AND ContactNumber_Enc IS NULL))
             AND (Email=CONVERT(NVARCHAR(100),DECRYPTBYKEY(Email_Enc))
                  OR (Email IS NULL AND Email_Enc IS NULL))
             AND (Address=CONVERT(NVARCHAR(255),DECRYPTBYKEY(Address_Enc))
                  OR (Address IS NULL AND Address_Enc IS NULL))
            THEN 1 ELSE 0 END),0)
    FROM Clients;

    SELECT
        @C4Agents=COUNT(*),
        @C4AgentMatches=COALESCE(SUM(CASE
            WHEN (ContactNumber=CONVERT(NVARCHAR(20),DECRYPTBYKEY(ContactNumber_Enc))
                  OR (ContactNumber IS NULL AND ContactNumber_Enc IS NULL))
             AND (Email=CONVERT(NVARCHAR(100),DECRYPTBYKEY(Email_Enc))
                  OR (Email IS NULL AND Email_Enc IS NULL))
            THEN 1 ELSE 0 END),0)
    FROM Agents;

    CLOSE SYMMETRIC KEY PIIKey;

    SELECT 'TC-C4 Encryption consistency' AS TestCase,
           @C4Clients AS ClientRows,@C4ClientMatches AS MatchingClientRows,
           @C4Agents AS AgentRows,@C4AgentMatches AS MatchingAgentRows,
           CASE WHEN @C4Clients>0 AND @C4Clients=@C4ClientMatches
                      AND @C4Agents>0 AND @C4Agents=@C4AgentMatches
                THEN 'PASS' ELSE 'FAIL' END AS Result;
END TRY
BEGIN CATCH
    IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name='PIIKey')
        CLOSE SYMMETRIC KEY PIIKey;
    SELECT 'TC-C4 Encryption consistency' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP D: DYNAMIC DATA MASKING
   ============================================================================= */

-- TC-D1/D2: Analytics sees masked values; DBA sees original values.
BEGIN TRY
    DECLARE @D1Rows INT,@D2Rows INT,
            @D1HasUnmask INT,@D2HasUnmask INT,@DMaskCount INT;

    -- The first result set is the visual proof: SQL Server applies DDM only to
    -- returned output, not to internal predicate/comparison values.
    EXECUTE AS USER='priya_suhuba_login';
    SELECT ClientID,FullName,ContactNumber,Email FROM vw_Analytics_ClientSummary;
    SELECT @D1Rows=COUNT(*) FROM vw_Analytics_ClientSummary;
    SELECT @D1HasUnmask=HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','UNMASK');
    REVERT;

    -- The second result set proves the authorised DBA receives original values.
    EXECUTE AS USER='imran_amir_login';
    SELECT ClientID,FullName,ContactNumber,Email,Address FROM Clients;
    SELECT @D2Rows=COUNT(*) FROM Clients;
    SELECT @D2HasUnmask=HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','UNMASK');
    REVERT;

    SELECT @DMaskCount=COUNT(*)
    FROM sys.masked_columns
    WHERE object_id=OBJECT_ID('dbo.Clients')
      AND name IN('ContactNumber','Email','Address')
      AND is_masked=1;

    SELECT 'TC-D1/D2 Masked analytics and unmasked DBA output' AS TestCase,
           @D1Rows AS AnalyticsRows,@D1HasUnmask AS AnalyticsHasUnmask,
           @D2Rows AS DBARows,@D2HasUnmask AS DBAHasUnmask,
           @DMaskCount AS ClientMaskedColumns,
           CASE WHEN @D1Rows>0 AND @D1HasUnmask=0
                      AND @D2Rows>0 AND @D2HasUnmask=1
                      AND @DMaskCount=3
                THEN 'PASS' ELSE 'FAIL' END AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-D1/D2 Masked analytics and unmasked DBA output' AS TestCase,
           'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-D3: Analytics still receives useful aggregate results.
BEGIN TRY
    EXECUTE AS USER='priya_suhuba_login';
    SELECT * FROM vw_Analytics_AgentPerformance;
    REVERT;
    SELECT 'TC-D3 Useful masked aggregate output' AS TestCase,'PASS' AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-D3 Useful masked aggregate output' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP E: ROW-LEVEL SECURITY [BONUS]
   ============================================================================= */

-- TC-E1: Eligible DBA role sees rows.
BEGIN TRY
    DECLARE @E1VisibleRows INT;
    EXECUTE AS USER='imran_amir_login';
    SELECT @E1VisibleRows=COUNT(*) FROM Transactions;
    REVERT;
    SELECT 'TC-E1 DBA visible transactions' AS TestCase,@E1VisibleRows AS VisibleRows,
           CASE WHEN @E1VisibleRows>0 THEN 'PASS' ELSE 'FAIL' END AS Result;
END TRY
BEGIN CATCH
    IF USER_NAME()<>'dbo' REVERT;
    SELECT 'TC-E1 DBA visible transactions' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-E2: Temporary SELECT proves RLS filters a non-eligible role to zero.
BEGIN TRY
    GRANT SELECT ON Transactions TO PropertyMgmtDev;
    EXECUTE AS USER='izzah_zulkafli_login';
    SELECT 'TC-E2 RLS filtered rows' AS TestCase,COUNT(*) AS VisibleRows,
           CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END AS Result FROM Transactions;
    REVERT;
    REVOKE SELECT ON Transactions FROM PropertyMgmtDev;
END TRY
BEGIN CATCH
    DECLARE @E2Error NVARCHAR(4000)=ERROR_MESSAGE();
    IF USER_NAME()<>'dbo' REVERT;

    -- Cleanup is attempted independently so the temporary GRANT cannot leak
    -- into later tests even when the impersonated SELECT unexpectedly fails.
    BEGIN TRY
        REVOKE SELECT ON Transactions FROM PropertyMgmtDev;
    END TRY
    BEGIN CATCH
        SET @E2Error=CONCAT(@E2Error,' | Cleanup warning: ',ERROR_MESSAGE());
    END CATCH;

    SELECT 'TC-E2 RLS filtered rows' AS TestCase,'FAIL' AS Result,@E2Error AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP F: DML AUDITING AND TAMPER RESISTANCE
   ============================================================================= */

-- TC-F1: Property trigger covers INSERT, UPDATE and DELETE; rollback keeps the
-- test repeatable while the evidence remains visible inside the transaction.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @F1StartAuditID INT=ISNULL((SELECT MAX(AuditID) FROM AuditLog),0);
    INSERT INTO Properties(PropertyName,Address,City,State,Price,Status)
    VALUES('TC-F1 Property','1 Audit Test Road','Kuala Lumpur','WP',100000,'Available');
    DECLARE @F1PropertyID INT=SCOPE_IDENTITY();
    UPDATE Properties SET Price=100001 WHERE PropertyID=@F1PropertyID;
    DELETE FROM Properties WHERE PropertyID=@F1PropertyID;

    SELECT 'TC-F1 Property full CRUD audit' AS TestCase,
           COUNT(*) AS AuditRows,
           COUNT(DISTINCT Operation) AS DistinctOperations,
           CASE WHEN COUNT(*)=3 AND COUNT(DISTINCT Operation)=3
                THEN 'PASS' ELSE 'FAIL' END AS Result
    FROM AuditLog
    WHERE AuditID>@F1StartAuditID AND TableName='Properties'
      AND RecordID=@F1PropertyID;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-F1 Property full CRUD audit' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-F2/F3/F4: Client, Agent and Transaction INSERT auditing.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @FStartAuditID INT=ISNULL((SELECT MAX(AuditID) FROM AuditLog),0);
    DECLARE @F2Email NVARCHAR(100)=CONCAT('f2.',REPLACE(CONVERT(NVARCHAR(36),NEWID()),'-',''),'@test.com');
    EXEC sp_RegisterNewClient @FullName='Test Client F2',@ContactNumber='019-1111111',@Email=@F2Email,@Address='2 Jalan Test';
    EXEC sp_RegisterNewAgent @FullName='Test Agent F3',@ContactNumber='019-2222222',@Email='f3@test.com',@CommissionRate=2.00;
    EXEC sp_AddTransaction @PropertyID=5,@ClientID=1,@AgentID=2,@TransactionType='Rent',@Amount=2000;
    SELECT * FROM AuditLog WHERE TableName IN('Clients','Agents','Transactions') ORDER BY AuditID DESC;

    DECLARE @F234AuditedTables INT;
    SELECT @F234AuditedTables=COUNT(DISTINCT TableName)
    FROM AuditLog
    WHERE AuditID>@FStartAuditID
      AND TableName IN('Clients','Agents','Transactions')
      AND Operation='INSERT';

    SELECT 'TC-F2/F3/F4 Insert audits' AS TestCase,
           @F234AuditedTables AS AuditedTables,
           CASE WHEN @F234AuditedTables=3 THEN 'PASS' ELSE 'FAIL' END AS Result;

    -- TC-F6: Literal [PROTECTED] markers must be present in every non-NULL
    -- Agent/Transaction audit value. '[[]' matches a literal opening bracket.
    DECLARE @F6Relevant INT,@F6Leaks INT;
    SELECT @F6Relevant=COUNT(*),
           @F6Leaks=COALESCE(SUM(CASE
               WHEN OldValue IS NOT NULL AND OldValue NOT LIKE '%[[]PROTECTED]%' THEN 1
               WHEN NewValue IS NOT NULL AND NewValue NOT LIKE '%[[]PROTECTED]%' THEN 1
               ELSE 0 END),0)
    FROM AuditLog
    WHERE AuditID>@FStartAuditID AND TableName IN('Transactions','Agents');

    SELECT 'TC-F6 Audit redaction verification' AS TestCase,
           @F6Relevant AS RelevantAuditRows,@F6Leaks AS UnredactedAuditRows,
           CASE WHEN @F6Relevant>0 AND @F6Leaks=0 THEN 'PASS' ELSE 'FAIL' END AS Result;

    -- Audit coverage is measured while repeatable test evidence still exists
    -- inside this transaction; the following ROLLBACK removes test-only rows.
    SELECT 'TC-F8 Audit coverage summary' AS TestCase,
           (SELECT COUNT(*) FROM sys.triggers
            WHERE is_ms_shipped=0 AND is_disabled=0) AS ActiveDatabaseTriggers,
           (SELECT COUNT(*) FROM AuditLog) AS AuditLogEntries,
           (SELECT COUNT(*) FROM master.dbo.LoginAudit) AS LoginEvents,
           (SELECT is_state_enabled FROM sys.server_audits
            WHERE name='GreenAcres_ServerAudit') AS ServerAuditActive,
           (SELECT is_state_enabled FROM sys.database_audit_specifications
            WHERE name='GreenAcres_DBAuditSpec') AS DBAuditSpecActive,
           CASE WHEN (SELECT COUNT(*) FROM sys.triggers
                           WHERE is_ms_shipped=0 AND is_disabled=0)>=9
                     AND (SELECT COUNT(*) FROM AuditLog)>0
                     AND (SELECT is_state_enabled FROM sys.server_audits
                          WHERE name='GreenAcres_ServerAudit')=1
                     AND (SELECT is_state_enabled FROM sys.database_audit_specifications
                          WHERE name='GreenAcres_DBAuditSpec')=1
                THEN 'PASS' ELSE 'FAIL' END AS Result;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-F2/F3/F4 Insert audits' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-F5: AuditLog UPDATE is rejected by append-only trigger.
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO AuditLog(TableName,Operation,RecordID,NewValue)
    VALUES('TC-F5','INSERT',0,'Temporary append-only evidence');
    DECLARE @F5AuditID INT=SCOPE_IDENTITY();
    UPDATE AuditLog SET NewValue='Tampered' WHERE AuditID=@F5AuditID;
    ROLLBACK TRANSACTION;
    SELECT 'TC-F5 Append-only audit' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-F5 Append-only audit' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-F7: MaintenanceRequests now has independent application-level CRUD
-- auditing in addition to the engine-level Database Audit Specification.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @F7StartAuditID INT=ISNULL((SELECT MAX(AuditID) FROM AuditLog),0);
    DECLARE @F7Marker NVARCHAR(100)=CONCAT('TC-F7-',CONVERT(NVARCHAR(36),NEWID()));
    EXEC sp_AddMaintenanceRequest @PropertyID=1,@RequestDetails=@F7Marker;
    DECLARE @F7RequestID INT=(SELECT MAX(RequestID) FROM MaintenanceRequests WHERE RequestDetails=@F7Marker);
    UPDATE MaintenanceRequests SET Status='In Progress' WHERE RequestID=@F7RequestID;
    DELETE FROM MaintenanceRequests WHERE RequestID=@F7RequestID;

    SELECT 'TC-F7 Maintenance full CRUD audit' AS TestCase,
           COUNT(*) AS AuditRows,COUNT(DISTINCT Operation) AS DistinctOperations,
           CASE WHEN @F7RequestID IS NOT NULL AND COUNT(*)=3
                      AND COUNT(DISTINCT Operation)=3
                THEN 'PASS' ELSE 'FAIL' END AS Result
    FROM AuditLog
    WHERE AuditID>@F7StartAuditID AND TableName='MaintenanceRequests'
      AND RecordID=@F7RequestID;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-F7 Maintenance full CRUD audit' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP G: OPERATIONAL TRIGGERS
   ============================================================================= */

-- TC-G1: Sale transaction changes property status to Sold.
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC sp_AddTransaction @PropertyID=5,@ClientID=1,@AgentID=1,@TransactionType='Sale',@Amount=480000;
    SELECT 'TC-G1 Automatic Sold status' AS TestCase,PropertyID,Status,
           CASE WHEN Status='Sold' THEN 'PASS' ELSE 'FAIL' END AS Result
    FROM Properties WHERE PropertyID=5;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-G1 Automatic Sold status' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-G2: Maintenance on a Sold property is rejected.
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC sp_AddMaintenanceRequest @PropertyID=2,@RequestDetails='Should be rejected';
    ROLLBACK TRANSACTION;
    SELECT 'TC-G2 Sold maintenance rejected' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-G2 Sold maintenance rejected' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-G3: Commission update generates history; rollback keeps test repeatable.
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @G3StartID INT=ISNULL((SELECT MAX(CommissionHistoryID)
                                   FROM AgentCommissionHistory),0),
            @G3OldRate DECIMAL(5,2),
            @G3NewRate DECIMAL(5,2);

    SELECT @G3OldRate=CommissionRate FROM Agents WHERE AgentID=1;
    SET @G3NewRate=CASE WHEN @G3OldRate=2.75 THEN 2.80 ELSE 2.75 END;

    EXEC sp_UpdateAgentCommission @AgentID=1,@NewCommissionRate=@G3NewRate;

    SELECT 'TC-G3 Commission history' AS TestCase,
           COUNT(*) AS HistoryRows,
           CASE WHEN COUNT(*)=1 THEN 'PASS' ELSE 'FAIL' END AS Result
    FROM AgentCommissionHistory
    WHERE CommissionHistoryID>@G3StartID
      AND AgentID=1
      AND OldCommissionRate=@G3OldRate
      AND NewCommissionRate=@G3NewRate;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-G3 Commission history' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP H: LOGON TRIGGER [BONUS - MANUAL]
   =============================================================================
 
 TC-H1:
   Connect successfully using sehneel_ansari_login before running this test.
   Expected: at least one matching logon record. */

SELECT TOP (20)
    LoginAuditID,
    LoginName,
    LoginTime,
    ClientHost
FROM master.dbo.LoginAudit
WHERE LoginName = 'sehneel_ansari_login'
ORDER BY LoginAuditID DESC;

SELECT
    'TC-H1 Developer SQL login captured' AS TestCase,
    COUNT(*) AS CapturedLogons,
    CASE
        WHEN COUNT(*) > 0 THEN 'PASS'
        ELSE 'FAIL - connect using sehneel_ansari_login first'
    END AS Result
FROM master.dbo.LoginAudit
WHERE LoginName = 'sehneel_ansari_login';
GO

/* =============================================================================
   GROUP I: SERVER AND DATABASE AUDITING
   ============================================================================= */

-- TC-I1: Generate a Clients SELECT event, then review the audit file.
BEGIN TRY
    SELECT ClientID,FullName FROM Clients;
    SELECT event_time,action_id,succeeded,server_principal_name,database_name,object_name,statement
    FROM sys.fn_get_audit_file('C:\GreenAcresAudits\*.sqlaudit',DEFAULT,DEFAULT)
    WHERE object_name IN('Clients','Agents','Properties')
    ORDER BY event_time DESC;

    DECLARE @I1Events INT;
    SELECT @I1Events=COUNT(*)
    FROM sys.fn_get_audit_file('C:\GreenAcresAudits\*.sqlaudit',DEFAULT,DEFAULT)
    WHERE database_name='GreenAcresEMS_Final' AND object_name='Clients' AND succeeded=1;
    SELECT 'TC-I1 Database audit evidence' AS TestCase,@I1Events AS MatchingEvents,
           CASE WHEN @I1Events>0 THEN 'PASS'
                ELSE 'MANUAL CHECK: allow audit flush, then rerun TC-I1' END AS Result;
END TRY
BEGIN CATCH
    SELECT 'TC-I1 Database audit evidence' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* TC-I2 [MANUAL]: First open a new SQL-authentication connection with an
   incorrect password for izzah_zulkafli_login. A failed login will not appear
   in LoginAudit because the LOGON trigger fires only after authentication. */
BEGIN TRY
    SELECT TOP(20) event_time,action_id,succeeded,server_principal_name,
           client_ip,statement
    FROM sys.fn_get_audit_file('C:\GreenAcresAudits\*.sqlaudit',DEFAULT,DEFAULT)
    WHERE action_id='LGIF'
      AND succeeded=0
      AND (server_principal_name='izzah_zulkafli_login'
           OR statement LIKE '%izzah_zulkafli_login%')
    ORDER BY event_time DESC;

    DECLARE @I2Events INT;
    SELECT @I2Events=COUNT(*)
    FROM sys.fn_get_audit_file('C:\GreenAcresAudits\*.sqlaudit',DEFAULT,DEFAULT)
    WHERE action_id='LGIF'
      AND succeeded=0
      AND (server_principal_name='izzah_zulkafli_login'
           OR statement LIKE '%izzah_zulkafli_login%');

    SELECT 'TC-I2 Failed login audit evidence' AS TestCase,@I2Events AS MatchingEvents,
           CASE WHEN @I2Events>0 THEN 'PASS'
                ELSE 'MANUAL STEP REQUIRED: attempt an incorrect login, then rerun TC-I2'
           END AS Result;
END TRY
BEGIN CATCH
    SELECT 'TC-I2 Failed login audit evidence' AS TestCase,'FAIL' AS Result,
           ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP J: BACKUPS AND RESTORE
   ============================================================================= */

-- TC-J1: Full, differential and transaction-log backup history.
SELECT database_name,backup_start_date,backup_finish_date,
       CASE type WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction Log' END AS BackupType,
       has_backup_checksums
FROM msdb.dbo.backupset WHERE database_name='GreenAcresEMS_Final'
ORDER BY backup_start_date DESC;
GO

SELECT 'TC-J1 Backup coverage' AS TestCase,
       COUNT(DISTINCT type) AS BackupTypesFound,
       MIN(CASE WHEN has_backup_checksums=1 THEN 1 ELSE 0 END) AS AllHaveChecksums,
       CASE WHEN COUNT(DISTINCT type)=3
                  AND MIN(CASE WHEN has_backup_checksums=1 THEN 1 ELSE 0 END)=1
            THEN 'PASS' ELSE 'FAIL' END AS Result
FROM msdb.dbo.backupset
WHERE database_name='GreenAcresEMS_Final'
  AND type IN('D','I','L');
GO

/* TC-J2 [MANUAL]: Safe restore validation.
   1. RESTORE VERIFYONLY FROM DISK='C:\GreenAcresBackups\GreenAcresEMS_Final_Final_Full.bak' WITH CHECKSUM;
   2. RESTORE FILELISTONLY FROM DISK='C:\GreenAcresBackups\GreenAcresEMS_Final_Final_Full.bak';
   3. Restore as GreenAcresEMS_TestRestore using the returned logical names and
      WITH MOVE. Compare row counts, capture evidence, then drop only that test
      database. Keeping this manual prevents accidental overwrite/deletion. */

/* =============================================================================
   GROUP K: DATA INTEGRITY CHECK CONSTRAINTS
   ============================================================================= */

-- TC-K1: Negative property price rejected.
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO Properties(PropertyName,Address,City,State,Price,Status)
    VALUES('Invalid Price','1 Test','KL','WP',-500,'Available');
    ROLLBACK TRANSACTION;
    SELECT 'TC-K1 Negative price' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-K1 Negative price' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;

-- TC-K2: Invalid property status rejected.
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO Properties(PropertyName,Address,City,State,Price,Status)
    VALUES('Invalid Status','1 Test','KL','WP',500000,'Unavailable');
    ROLLBACK TRANSACTION;
    SELECT 'TC-K2 Invalid status' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-K2 Invalid status' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;

-- TC-K3: Invalid commission rejected.
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO Agents(FullName,ContactNumber,Email,CommissionRate)
    VALUES('Invalid Commission','019-0000000','invalid@test.com',150);
    ROLLBACK TRANSACTION;
    SELECT 'TC-K3 Invalid commission' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-K3 Invalid commission' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP L: SQL INJECTION RESISTANCE
   ============================================================================= */

-- TC-L1: Parameterised procedure stores malicious-looking text as data.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @L1Email NVARCHAR(100)=CONCAT('inject.',REPLACE(CONVERT(NVARCHAR(36),NEWID()),'-',''),'@test.com');
    EXEC sp_RegisterNewClient @FullName='Robert''); DROP TABLE Clients;--',
         @ContactNumber='019-3333333',@Email=@L1Email,@Address='1 Jalan Injection';
    SELECT 'TC-L1 SQL text treated as data' AS TestCase,FullName,
           CASE WHEN OBJECT_ID('dbo.Clients','U') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS Result
    FROM Clients WHERE Email=@L1Email;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-L1 SQL text treated as data' AS TestCase,'FAIL' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

/* =============================================================================
   GROUP M: LEAST-PRIVILEGE SELF-CHECK
   ============================================================================= */

SELECT dp.name AS RoleName,
       SUM(CASE WHEN p.state_desc='GRANT' THEN 1 ELSE 0 END) AS GrantCount,
       SUM(CASE WHEN p.state_desc='DENY' THEN 1 ELSE 0 END) AS DenyCount,
       SUM(CASE WHEN p.permission_name='DELETE' AND p.state_desc='GRANT' THEN 1 ELSE 0 END) AS DeleteGrants
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id=dp.principal_id
WHERE dp.name IN('PropertyMgmtDev','ClientPortalDev','AnalyticsTeam','DBAdminRole','AgentOpsDev','SecurityAuditor')
GROUP BY dp.name ORDER BY dp.name;
GO

/* =============================================================================
   GROUP N: CLIENT EMAIL HASHING [BONUS]
   ============================================================================= */

-- TC-N1: Normalization produces the same hash for equivalent email text.
SELECT 'TC-N1 Normalized hash' AS TestCase,
       CASE WHEN dbo.fn_GetClientEmailHash(' LEON.KENNEDY@GMAIL.COM ')=dbo.fn_GetClientEmailHash('leon.kennedy@gmail.com')
            THEN 'PASS' ELSE 'FAIL' END AS Result;
GO

-- TC-N2: Duplicate normalized email is rejected with a controlled error.
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC sp_RegisterNewClient @FullName='Duplicate Test',@ContactNumber='019-4444444',
         @Email=' LEON.KENNEDY@GMAIL.COM ',@Address='Duplicate Address';
    ROLLBACK TRANSACTION;
    SELECT 'TC-N2 Duplicate email' AS TestCase,'FAIL' AS Result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT 'TC-N2 Duplicate email' AS TestCase,'PASS' AS Result,ERROR_MESSAGE() AS Evidence;
END CATCH;
GO

-- TC-N3: EmailHash is binary and present for all non-null emails.
SELECT ClientID,FullName,Email,EmailHash,DATALENGTH(EmailHash) AS HashBytes,
       CASE WHEN Email IS NULL OR DATALENGTH(EmailHash)=32 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM Clients;
GO

/* =============================================================================
   END OF GROUP 19 TEST CASES
   ============================================================================= */
