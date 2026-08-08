/* =============================================================================
   GREEN ACRES REALTY - ESTATE MANAGEMENT SYSTEM (EMS)
   Database Security Assignment - CT069-3-3
   Group 19 - Refined Full Implementation Script

   Run this file top to bottom, in order, in SQL Server Management Studio,
   against a fresh instance. Lines marked >>> CHANGE ME require a local
   folder path to be updated before running that section.
   ============================================================================= */


/* =============================================================================
   SECTION 0: DATABASE SETUP
   ============================================================================= */

-- Stop if an earlier build exists. This avoids mixing old test records or
-- security objects into the final demonstration. Remove the old lab database
-- manually only when you intentionally want a fresh rebuild.
IF DB_ID('GreenAcresEMS_Final') IS NOT NULL
    THROW 50000, 'GreenAcresEMS_Final already exists. Use a fresh database for this build.', 1;
GO

CREATE DATABASE GreenAcresEMS_Final;
GO

USE GreenAcresEMS_Final;
GO

-- FULL recovery model enables transaction log backups (Availability requirement)
ALTER DATABASE GreenAcresEMS_Final SET RECOVERY FULL;
GO


/* =============================================================================
   SECTION 1: SCHEMA - BASE TABLES
   Purpose: Rebuild the EMS schema originally provided by the previous
   developers (Appendix I), improved from the start with:
     - CHECK constraints (Integrity - invalid values are rejected at the
       database engine level, regardless of which procedure or role
       attempts the write - this also means our stored procedures do not
       need to duplicate this validation logic themselves)
     - Change-tracking columns (ModifiedDate/ModifiedBy) on Properties
     - Placeholder encrypted columns on Clients/Agents, populated once the
       encryption keys are created in Section 5
   ============================================================================= */

CREATE TABLE Properties (
    PropertyID      INT IDENTITY(1,1) PRIMARY KEY,
    PropertyName    NVARCHAR(150) NOT NULL,
    Address         NVARCHAR(255) NOT NULL,
    City            NVARCHAR(100) NOT NULL,
    State           NVARCHAR(100) NOT NULL,
    Price           DECIMAL(18,2) NOT NULL CONSTRAINT CK_Properties_Price CHECK (Price >= 0),
    Status          NVARCHAR(50)  NOT NULL CONSTRAINT DF_Properties_Status DEFAULT 'Available'
                    CONSTRAINT CK_Properties_Status CHECK (Status IN ('Available','Sold','Rented')),
    CreatedDate     DATETIME NOT NULL CONSTRAINT DF_Properties_Created DEFAULT GETDATE(),
    ModifiedDate    DATETIME NULL,
    ModifiedBy      NVARCHAR(100) NULL
);
GO

CREATE TABLE Clients (
    ClientID           INT IDENTITY(1,1) PRIMARY KEY,
    FullName           NVARCHAR(100) NOT NULL,
    ContactNumber      NVARCHAR(20)  NULL,
    Email              NVARCHAR(100) NULL,
    Address            NVARCHAR(255) NULL,
    ContactNumber_Enc  VARBINARY(256) NULL,   -- AES-256 ciphertext, populated in Section 5
    Email_Enc          VARBINARY(256) NULL,
    Address_Enc        VARBINARY(256) NULL,
    RegisteredDate     DATETIME NOT NULL CONSTRAINT DF_Clients_Registered DEFAULT GETDATE()
);
GO

CREATE TABLE Agents (
    AgentID            INT IDENTITY(1,1) PRIMARY KEY,
    FullName           NVARCHAR(100) NOT NULL,
    ContactNumber      NVARCHAR(20)  NULL,
    Email              NVARCHAR(100) NULL,
    CommissionRate     DECIMAL(5,2)  NOT NULL
                       CONSTRAINT CK_Agents_CommissionRate CHECK (CommissionRate BETWEEN 0 AND 100),
    ContactNumber_Enc  VARBINARY(256) NULL,
    Email_Enc          VARBINARY(256) NULL,
    JoinedDate         DATETIME NOT NULL CONSTRAINT DF_Agents_Joined DEFAULT GETDATE()
);
GO

CREATE TABLE Transactions (
    TransactionID    INT IDENTITY(1,1) PRIMARY KEY,
    PropertyID       INT NOT NULL CONSTRAINT FK_Txn_Property   FOREIGN KEY REFERENCES Properties(PropertyID),
    ClientID         INT NOT NULL CONSTRAINT FK_Txn_Client     FOREIGN KEY REFERENCES Clients(ClientID),
    AgentID          INT NOT NULL CONSTRAINT FK_Txn_Agent      FOREIGN KEY REFERENCES Agents(AgentID),
    TransactionType  NVARCHAR(50) NOT NULL CONSTRAINT CK_Txn_Type CHECK (TransactionType IN ('Sale','Rent')),
    TransactionDate  DATETIME NOT NULL CONSTRAINT DF_Txn_Date DEFAULT GETDATE(),
    Amount           DECIMAL(18,2) NOT NULL CONSTRAINT CK_Txn_Amount CHECK (Amount >= 0)
);
GO

CREATE TABLE MaintenanceRequests (
    RequestID       INT IDENTITY(1,1) PRIMARY KEY,
    PropertyID      INT NOT NULL CONSTRAINT FK_Maint_Property FOREIGN KEY REFERENCES Properties(PropertyID),
    RequestDetails  NVARCHAR(MAX) NULL,
    RequestDate     DATETIME NOT NULL CONSTRAINT DF_Maint_Date DEFAULT GETDATE(),
    Status          NVARCHAR(50) NOT NULL CONSTRAINT DF_Maint_Status DEFAULT 'Pending'
                    CONSTRAINT CK_Maint_Status CHECK (Status IN ('Pending','In Progress','Completed'))
);
GO

-- Indexes on foreign keys used heavily by views/joins - supports Availability
-- (query performance) as the dataset grows beyond sample-data size.
CREATE INDEX IX_Transactions_PropertyID ON Transactions(PropertyID);
CREATE INDEX IX_Transactions_ClientID   ON Transactions(ClientID);
CREATE INDEX IX_Transactions_AgentID    ON Transactions(AgentID);
CREATE INDEX IX_Maintenance_PropertyID  ON MaintenanceRequests(PropertyID);
GO


/* =============================================================================
   SECTION 2: SAMPLE DATA
   Purpose: Populate all tables with realistic data so security features can
   be demonstrated and tested. Client names below are deliberately unrelated
   to the IT department staff created in Section 3 - the assignment brief
   explicitly separates "clients" (customers) from "developers" (internal
   staff), and using distinct name pools avoids any ambiguity between them.
   ============================================================================= */

INSERT INTO Properties (PropertyName, Address, City, State, Price, Status) VALUES
('Aurora Villa', '12 Jalan Bahagia', 'Kuala Lumpur', 'WP', 850000, 'Available'),
('Meadow Terrace House', '5 Jalan Damai', 'Petaling Jaya', 'Selangor', 620000, 'Sold'),
('Lotus Crest Apartment', '88 Jalan Orkid', 'Rawang', 'Selangor', 320000, 'Available'),
('Cedar Maple Bungalow', '21 Jalan Maple', 'Shah Alam', 'Selangor', 1250000, 'Rented'),
('Bluewater Condo', '3 Jalan Tasik', 'Puchong', 'Selangor', 480000, 'Available'),
('Palm Grove Residence', '17 Jalan Sawit', 'Klang', 'Selangor', 560000, 'Available'),
('Highridge Cottage', '9 Jalan Bukit', 'Cheras', 'WP', 700000, 'Sold'),
('Sunset Riverside Loft', '45 Jalan Sungai', 'Kajang', 'Selangor', 390000, 'Available'),
('Aurora Heights', '2 Jalan Emas', 'Ampang', 'WP', 980000, 'Rented'),
('Tranquil Haven Home', '30 Jalan Tenang', 'Rawang', 'Selangor', 410000, 'Available');
GO

INSERT INTO Clients (FullName, ContactNumber, Email, Address) VALUES
('Leon Kennedy',    '012-3635689', 'leon.kennedy@gmail.com',   '15 Jalan SS2/24, SS2, 47300 Petaling Jaya, Selangor'),
('Woo Do Hwan',     '013-0227763', 'woo.dohwan@yahoo.com',     '7 Jalan Kenanga 5, Bandar Puchong Jaya, 47100 Puchong, Selangor'),
('Jay Chou',        '019-4316695', 'jay.chou@gmail.com',       '23 Jalan Anggerik, Taman Melawati, 53100 Kuala Lumpur'),
('Pravin Kumar',    '016-6767676', 'pravin.kumar@hotmail.com', '4 Jalan Bunga Raya 3, Taman Sri Rawang, 48000 Rawang, Selangor'),
('Ada Wong',        '017-7234523', 'ada.wong@gmail.com',       '19 Jalan Pinang, Taman Desa, 58100 Kuala Lumpur'),
('Tsang Da Xin',    '018-0293833', 'daxin.tsang@yahoo.com',    '2 Jalan Sutera 12, Taman Sentosa, 41200 Klang, Selangor'),
('Dewi Rajan Priya','019-929945',  'dewi.rajanpriya@gmail.com','31 Jalan Cempaka 8, Bandar Baru Bangi, 43650 Bangi, Selangor'),
('Summitha Kumarin Ravichander', '011-3334456', 'summitha.kr@outlook.com', '6 Jalan Kajang Impian, Taman Kajang Impian, 43000 Kajang, Selangor'),
('James Chan Hong Yu', '012-1909834', 'jameschan.hy@gmail.com', '11 Jalan Ampang Utama 2/1, Taman Dato Ahmad Razali, 68000 Ampang, Selangor'),
('Low Yan Cheng',   '013-2123345', 'yancheng.low@yahoo.com',   '9 Jalan Cheras Baru, Taman Cheras Baru, 56100 Cheras, Kuala Lumpur');
GO

INSERT INTO Agents (FullName, ContactNumber, Email, CommissionRate) VALUES
('Nur Alia Zahid',   '019-1112222', 'aisyah.r@greenacres.com',  2.50),
('Ethan Wong',       '017-2223333', 'david.lim@greenacres.com', 3.00),
('Siti Kavitha Nair','018-3334444', 'kavitha.s@greenacres.com', 2.75),
('Ahmad Zulkarnain', '016-4445555', 'zul.k@greenacres.com',     3.25),
('Lina Grace Ho',    '012-5556666', 'grace.tan@greenacres.com', 2.90);
GO

INSERT INTO Transactions (PropertyID, ClientID, AgentID, TransactionType, Amount) VALUES
(2, 1, 1, 'Sale', 620000),
(4, 2, 2, 'Rent', 3500),
(7, 3, 3, 'Sale', 700000),
(9, 4, 4, 'Rent', 4200),
(1, 5, 1, 'Sale', 850000),
(3, 6, 2, 'Rent', 1800),
(5, 7, 3, 'Sale', 480000),
(6, 8, 4, 'Rent', 2200),
(8, 9, 5, 'Sale', 390000),
(10, 10, 1, 'Rent', 1950);
GO

INSERT INTO MaintenanceRequests (PropertyID, RequestDetails, Status) VALUES
(2, 'Water seepage from ceiling causing damp patches in master bedroom', 'Completed'),
(4, 'Air conditioner not cooling properly, suspected refrigerant issue', 'In Progress'),
(7, 'Broken window glass in living room requiring replacement', 'Pending'),
(9, 'Leaking pipe detected under kitchen sink cabinet', 'Completed'),
(1, 'Electrical power trip occurs when using study room socket', 'Pending'),
(5, 'Automatic gate system unresponsive to remote control', 'In Progress'),
(6, 'Water heater producing unusual loud sounds, replacement needed', 'Completed'),
(8, 'Mold buildup spreading on bathroom ceiling surface', 'Pending');
GO


/* =============================================================================
   SECTION 3: DEPARTMENTS AND APPLICATION USERS (SALTED HASHING)
   Purpose: Represent the new IT division's departments, and demonstrate a
   complete, correct password lifecycle - creation and verification - using
   one-way salted hashing (SHA2_512). The salt is generated once per user
   and stored alongside the hash; verification re-hashes the supplied
   password with that same stored salt and compares the result. At no point
   is a plain-text password ever stored, logged, or displayed - not even to
   Database Administration (Section 10).
   ============================================================================= */

CREATE TABLE Departments (
    DepartmentID   INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL
);
GO

INSERT INTO Departments (DepartmentName) VALUES
('Property Management Development'),
('Client Portal Development'),
('Analytics'),
('Database Administration'),
('Agent Operations Development');
GO

CREATE TABLE Users (
    UserID        INT IDENTITY(1,1) PRIMARY KEY,
    Username      NVARCHAR(50) UNIQUE NOT NULL,
    PasswordSalt  VARBINARY(32) NOT NULL,              -- cryptographically random per-user salt
    PasswordHash  VARBINARY(64) NOT NULL,              -- SHA2_512(salt + password); irreversible
    DepartmentID  INT NOT NULL CONSTRAINT FK_Users_Department FOREIGN KEY REFERENCES Departments(DepartmentID),
    FailedLoginCount INT NOT NULL CONSTRAINT DF_Users_Failed DEFAULT 0,
    IsActive      BIT NOT NULL CONSTRAINT DF_Users_Active DEFAULT 1,
    LastSuccessfulLogin DATETIME2(0) NULL,
    LastFailedLogin DATETIME2(0) NULL,
    CreatedDate   DATETIME2(0) NOT NULL CONSTRAINT DF_Users_Created DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Users_FailedLogin CHECK (FailedLoginCount BETWEEN 0 AND 5)
);
GO

-- -----------------------------------------------------------------------
-- 3.1: Create-user procedure - generates a fresh random salt per account
-- and stores only the resulting hash, never the plaintext password itself.
-- -----------------------------------------------------------------------
CREATE PROCEDURE sp_CreateAppUser
    @Username NVARCHAR(50),
    @PlaintextPassword NVARCHAR(128),
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NULLIF(LTRIM(RTRIM(@Username)), N'') IS NULL
        THROW 50001, 'Username is required.', 1;

    IF @PlaintextPassword IS NULL OR LEN(@PlaintextPassword) < 12
        THROW 50002, 'Password must contain at least 12 characters.', 1;

    IF NOT EXISTS (SELECT 1 FROM Departments WHERE DepartmentID=@DepartmentID)
        THROW 50003, 'Department does not exist.', 1;

    DECLARE @Salt VARBINARY(32) = CRYPT_GEN_RANDOM(32);
    INSERT INTO Users (Username, PasswordSalt, PasswordHash, DepartmentID)
    VALUES (
        @Username,
        @Salt,
        HASHBYTES('SHA2_512', @Salt + CONVERT(VARBINARY(MAX), @PlaintextPassword)),
        @DepartmentID
    );
END;
GO

-- -----------------------------------------------------------------------
-- 3.2: Verify-login procedure - re-hashes the supplied password with the
-- user's stored salt and compares to the stored hash. Returns 1 (match)
-- or 0 (no match) via output parameter; the plaintext password is never
-- retained or compared to anything other than a freshly computed hash.
-- -----------------------------------------------------------------------
CREATE PROCEDURE sp_VerifyAppUserLogin
    @Username NVARCHAR(50),
    @PlaintextPassword NVARCHAR(128),
    @IsValid BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @IsValid = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UserID INT,
                @Salt VARBINARY(32),
                @StoredHash VARBINARY(64),
                @IsActive BIT;

        -- Lock the row so simultaneous failures cannot bypass the counter.
        SELECT @UserID=UserID,@Salt=PasswordSalt,@StoredHash=PasswordHash,@IsActive=IsActive
        FROM Users WITH (UPDLOCK,HOLDLOCK)
        WHERE Username=@Username;

        IF @UserID IS NULL OR @IsActive=0
        BEGIN
            COMMIT TRANSACTION;
            RETURN;
        END;

        IF @StoredHash=HASHBYTES('SHA2_512',@Salt+CONVERT(VARBINARY(MAX),@PlaintextPassword))
        BEGIN
            UPDATE Users
            SET FailedLoginCount=0,LastSuccessfulLogin=SYSDATETIME()
            WHERE UserID=@UserID;
            SET @IsValid=1;
        END
        ELSE
        BEGIN
            UPDATE Users
            SET FailedLoginCount=CASE WHEN FailedLoginCount<5 THEN FailedLoginCount+1 ELSE 5 END,
                IsActive=CASE WHEN FailedLoginCount+1>=5 THEN 0 ELSE IsActive END,
                LastFailedLogin=SYSDATETIME()
            WHERE UserID=@UserID;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- DBA-controlled recovery for a legitimate account locked after five failures.
CREATE PROCEDURE sp_UnlockAppUser
    @Username NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users SET FailedLoginCount=0,IsActive=1 WHERE Username=@Username;
    IF @@ROWCOUNT=0 THROW 50004, 'Application user was not found.', 1;
END;
GO

-- One application account per department, named after the staff member
-- responsible for it.
EXEC sp_CreateAppUser @Username='izzah.zulkafli', @PlaintextPassword='Izzah@2026App!',   @DepartmentID=1;  -- Property Management Dev
EXEC sp_CreateAppUser @Username='sehneel.ansari', @PlaintextPassword='Sehneel@2026App!', @DepartmentID=2;  -- Client Portal Dev
EXEC sp_CreateAppUser @Username='priya.suhuba',   @PlaintextPassword='Priya@2026App!',   @DepartmentID=3;  -- Analytics
EXEC sp_CreateAppUser @Username='imran.amir',     @PlaintextPassword='Imran@2026App!',   @DepartmentID=4;  -- Database Administration
EXEC sp_CreateAppUser @Username='lim.jiahui',     @PlaintextPassword='JiaHui@2026App!',  @DepartmentID=5;  -- Agent Operations Dev
GO

-- Verify: PasswordHash displays as unreadable binary - proof no plain-text
-- credential is stored anywhere in the table.
SELECT UserID, Username, PasswordHash, DepartmentID FROM Users;
GO

-- Demonstrate the verification procedure with both a correct and an
-- incorrect password, proving the hash comparison genuinely works.
DECLARE @Result BIT;

EXEC sp_VerifyAppUserLogin @Username='izzah.zulkafli', @PlaintextPassword='Izzah@2026App!', @IsValid=@Result OUTPUT;
SELECT 'Correct password' AS TestCase, @Result AS IsValid;

EXEC sp_VerifyAppUserLogin @Username='izzah.zulkafli', @PlaintextPassword='WrongPassword', @IsValid=@Result OUTPUT;
SELECT 'Incorrect password' AS TestCase, @Result AS IsValid;

-- Return the demonstration account to a clean state for the separate tests.
EXEC sp_UnlockAppUser @Username='izzah.zulkafli';
GO


/* =============================================================================
   SECTION 4: DATABASE ROLES AND SQL SERVER LOGINS
   Purpose: Create the actual SQL Server-level roles and logins that control
   real database permissions (distinct from the application-level Users
   table above). Each department gets one role; each staff member gets one
   login mapped to their department's role.

   CHECK_POLICY = ON enforces Windows password complexity rules and account
   lockout after repeated failed attempts - directly relevant to the
   FAILED_LOGIN_GROUP captured by Server Auditing (Section 14), since
   lockout is what actually stops a brute-force attempt in progress rather
   than merely logging that one occurred.
   CHECK_EXPIRATION = ON enforces periodic password expiry.
   ============================================================================= */

CREATE ROLE PropertyMgmtDev;
CREATE ROLE ClientPortalDev;
CREATE ROLE AnalyticsTeam;
CREATE ROLE DBAdminRole;
CREATE ROLE AgentOpsDev;
CREATE ROLE SecurityAuditor;
GO

-- Izzah Zulkafli - Property Management Development
CREATE LOGIN izzah_zulkafli_login WITH PASSWORD = 'Izzah@2026Strong!', CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE USER  izzah_zulkafli_login FOR LOGIN izzah_zulkafli_login;
ALTER ROLE PropertyMgmtDev ADD MEMBER izzah_zulkafli_login;

-- Sehneel Ansari - Client Portal Development
CREATE LOGIN sehneel_ansari_login WITH PASSWORD = 'Sehneel@2026Strong!', CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE USER  sehneel_ansari_login FOR LOGIN sehneel_ansari_login;
ALTER ROLE ClientPortalDev ADD MEMBER sehneel_ansari_login;

-- Priya Suhuba - Analytics
CREATE LOGIN priya_suhuba_login WITH PASSWORD = 'Priya@2026Strong!', CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE USER  priya_suhuba_login FOR LOGIN priya_suhuba_login;
ALTER ROLE AnalyticsTeam ADD MEMBER priya_suhuba_login;

-- Imran Amir - Database Administration
CREATE LOGIN imran_amir_login WITH PASSWORD = 'Imran@2026Strong!', CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE USER  imran_amir_login FOR LOGIN imran_amir_login;
ALTER ROLE DBAdminRole ADD MEMBER imran_amir_login;

-- Lim Jia Hui - Agent Operations Development
CREATE LOGIN limjiahui_login WITH PASSWORD = 'JiaHui@2026Strong!', CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE USER  limjiahui_login FOR LOGIN limjiahui_login;
ALTER ROLE AgentOpsDev ADD MEMBER limjiahui_login;

-- Independent auditor - reviews evidence but cannot change business data.
CREATE LOGIN security_auditor_login WITH PASSWORD = 'SecurityAudit@2026Strong!', CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE USER  security_auditor_login FOR LOGIN security_auditor_login;
ALTER ROLE SecurityAuditor ADD MEMBER security_auditor_login;
GO


/* =============================================================================
   SECTION 5: DATA PROTECTION - COLUMN-LEVEL ENCRYPTION (Confidentiality, at rest)
   Purpose: Protect Client/Agent PII with reversible AES-256 encryption -
   needed because the business has a legitimate need to recover the real
   phone number/email/address (e.g. to contact the client), unlike hashing.
   This is deliberately column-scoped rather than table- or database-wide,
   so that only the specific sensitive fields carry the performance/storage
   cost of encryption, and so different columns could use different keys
   in future if required.

   Design limitation and compensating controls: the inherited plaintext PII
   columns are retained to support legacy compatibility and demonstrate SQL
   Server Dynamic Data Masking. The AES-256 columns therefore demonstrate
   selective column-level encryption and controlled recovery, not complete
   elimination of plaintext at rest. Exposure is reduced through TDE, explicit
   base-table DENY permissions, controlled views/procedures and comprehensive
   auditing. A production migration should make encrypted storage authoritative
   and expose masked values through a secured application layer.
   ============================================================================= */

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'GreenAcres@MasterKey2026!';
GO

-- Allows the Master Key to auto-open for any valid session, required for
-- server-side decryption inside views/procedures without manual OPEN steps.
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;
GO

CREATE CERTIFICATE PIICert
    WITH SUBJECT = 'Certificate for Encrypting Client and Agent PII';
GO

CREATE SYMMETRIC KEY PIIKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE PIICert;
GO

-- Encrypt the sample data inserted in Section 2 (encrypted columns were
-- already present in the table definition, just NULL until now)
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

UPDATE Clients
SET ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), ContactNumber),
    Email_Enc         = ENCRYPTBYKEY(KEY_GUID('PIIKey'), Email),
    Address_Enc       = ENCRYPTBYKEY(KEY_GUID('PIIKey'), Address);

UPDATE Agents
SET ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), ContactNumber),
    Email_Enc         = ENCRYPTBYKEY(KEY_GUID('PIIKey'), Email);

CLOSE SYMMETRIC KEY PIIKey;
GO

-- Verify: encrypted columns show unreadable binary ciphertext
SELECT ClientID, FullName, ContactNumber_Enc, Email_Enc, Address_Enc FROM Clients;
SELECT AgentID, FullName, ContactNumber_Enc, Email_Enc FROM Agents;
GO

-- Demonstrate decryption: proves the data is recoverable for legitimate use
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
SELECT
    ClientID, FullName,
    CONVERT(NVARCHAR(20),  DECRYPTBYKEY(ContactNumber_Enc)) AS DecryptedContactNumber,
    CONVERT(NVARCHAR(100), DECRYPTBYKEY(Email_Enc))         AS DecryptedEmail,
    CONVERT(NVARCHAR(255), DECRYPTBYKEY(Address_Enc))       AS DecryptedAddress
FROM Clients;
CLOSE SYMMETRIC KEY PIIKey;
GO


/* =============================================================================
   SECTION 6: DATA PROTECTION - DYNAMIC DATA MASKING (Confidentiality, display)
   Purpose: Hide PII on-screen from roles without a legitimate need to see it
   (e.g. Analytics), while the real data remains intact underneath - a
   separate, complementary control to encryption (which protects data at
   rest; masking controls what's displayed at query time, and is bypassed
   for any principal holding UNMASK permission).
   ============================================================================= */

ALTER TABLE Clients ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
ALTER TABLE Clients ALTER COLUMN ContactNumber ADD MASKED WITH (FUNCTION = 'partial(3,"XXXXXXX",2)');
ALTER TABLE Clients ALTER COLUMN Address ADD MASKED WITH (FUNCTION = 'default()');

ALTER TABLE Agents ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
ALTER TABLE Agents ALTER COLUMN ContactNumber ADD MASKED WITH (FUNCTION = 'partial(3,"XXXXXXX",2)');
GO

-- Only DBAdminRole may see real values instead of masked placeholders
GRANT UNMASK TO DBAdminRole;
GO

/* =============================================================================
   SECTION 6.1: SENSITIVITY CLASSIFICATION [BONUS]
   Purpose: Label PII, credential and financial columns so live database
   metadata aligns with the report's Data Classification Matrix.

   Limitation: classification is governance metadata and does not itself
   restrict access. Encryption, masking, RBAC, TDE and auditing provide the
   actual protection. Version-specific DDL is dynamic so SQL Server versions
   below 2019 continue without a parser or catalog-view failure.
   ============================================================================= */

DECLARE @ClassificationMajorVersion INT =
    CAST(SERVERPROPERTY('ProductMajorVersion') AS INT);

IF @ClassificationMajorVersion >= 15
BEGIN
    EXEC sys.sp_executesql N'
        ADD SENSITIVITY CLASSIFICATION TO dbo.Clients.FullName
        WITH (LABEL=''Confidential'', INFORMATION_TYPE=''Name'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Clients.ContactNumber
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Clients.Email
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Clients.Address
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Clients.ContactNumber_Enc
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Encrypted Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Clients.Email_Enc
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Encrypted Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Clients.Address_Enc
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Encrypted Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Agents.ContactNumber
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Agents.Email
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Agents.ContactNumber_Enc
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Encrypted Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Agents.Email_Enc
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Encrypted Contact Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Agents.CommissionRate
        WITH (LABEL=''Confidential'', INFORMATION_TYPE=''Financial Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Transactions.Amount
        WITH (LABEL=''Confidential'', INFORMATION_TYPE=''Financial Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Users.PasswordSalt
        WITH (LABEL=''Restricted'', INFORMATION_TYPE=''Authentication Information'');
        ADD SENSITIVITY CLASSIFICATION TO dbo.Users.PasswordHash
        WITH (LABEL=''Restricted'', INFORMATION_TYPE=''Authentication Information'');
    ';
    PRINT 'Sensitivity classifications applied successfully.';
END
ELSE
BEGIN
    PRINT 'Sensitivity classification skipped: SQL Server 2019 or later is required. Existing protection controls remain active.';
END;
GO


/* =============================================================================
   SECTION 7: CLIENT PORTAL DEVELOPMENT - VIEWS, PROCEDURES, ACCESS CONTROL
   Purpose: Basic client info via a View; sensitive PII (decrypted) only via
   a Stored Procedure using WITH EXECUTE AS OWNER (the procedure holds the
   decryption permission, not the caller); writes via a Stored Procedure so
   encryption is applied automatically and consistently; direct table access
   denied entirely, forcing all access through these controlled objects.

   SQL Injection note: every write below uses parameterized stored
   procedure inputs (@FullName, @Email, etc.) rather than dynamic SQL string
   concatenation. Parameterized inputs are treated by SQL Server strictly as
   data, never as executable SQL text, which inherently prevents SQL
   injection regardless of what a caller supplies as input.
   ============================================================================= */

CREATE VIEW vw_ClientPortal_Clients AS
    SELECT ClientID, FullName, RegisteredDate
    FROM Clients;
GO
GRANT SELECT ON vw_ClientPortal_Clients TO ClientPortalDev;
GO

CREATE PROCEDURE sp_GetClientContactInfo
    @ClientID INT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
        SELECT ClientID,FullName,
               CONVERT(NVARCHAR(20),DECRYPTBYKEY(ContactNumber_Enc)) AS ContactNumber,
               CONVERT(NVARCHAR(100),DECRYPTBYKEY(Email_Enc)) AS Email,
               CONVERT(NVARCHAR(255),DECRYPTBYKEY(Address_Enc)) AS Address
        FROM Clients WHERE ClientID=@ClientID;
        CLOSE SYMMETRIC KEY PIIKey;
    END TRY
    BEGIN CATCH
        IF EXISTS(SELECT 1 FROM sys.openkeys WHERE key_name=N'PIIKey')
            CLOSE SYMMETRIC KEY PIIKey;
        THROW;
    END CATCH
END;
GO
GRANT EXECUTE ON sp_GetClientContactInfo TO ClientPortalDev;
GO

CREATE PROCEDURE sp_RegisterNewClient
    @FullName NVARCHAR(100),
    @ContactNumber NVARCHAR(20),
    @Email NVARCHAR(100),
    @Address NVARCHAR(255)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
    INSERT INTO Clients (FullName, ContactNumber, Email, Address, ContactNumber_Enc, Email_Enc, Address_Enc)
    VALUES (
        @FullName, @ContactNumber, @Email, @Address,
        ENCRYPTBYKEY(KEY_GUID('PIIKey'), @ContactNumber),
        ENCRYPTBYKEY(KEY_GUID('PIIKey'), @Email),
        ENCRYPTBYKEY(KEY_GUID('PIIKey'), @Address)
    );
    CLOSE SYMMETRIC KEY PIIKey;
END;
GO
GRANT EXECUTE ON sp_RegisterNewClient TO ClientPortalDev;
GO

DENY SELECT, INSERT, UPDATE, DELETE ON Clients TO ClientPortalDev;
GO


/* =============================================================================
   SECTION 8: PROPERTY MANAGEMENT DEVELOPMENT - VIEWS, PROCEDURES, ACCESS
   Purpose: No PII involved (Properties/MaintenanceRequests are business
   data), so this is a simpler controlled read/write layer. Note that
   invalid Status/Price values are already rejected by the CHECK
   constraints in Section 1, so these procedures do not need their own
   duplicate validation logic.
   ============================================================================= */

CREATE VIEW vw_PropertyMgmt_Properties AS
    SELECT
        p.PropertyID, p.PropertyName, p.Address, p.City, p.State, p.Price,
        p.Status, p.CreatedDate, p.ModifiedDate, p.ModifiedBy,
        (SELECT COUNT(*) FROM MaintenanceRequests mr
         WHERE mr.PropertyID = p.PropertyID AND mr.Status <> 'Completed') AS OpenMaintenanceRequests
    FROM Properties p;
GO
GRANT SELECT ON vw_PropertyMgmt_Properties TO PropertyMgmtDev;
GO

CREATE VIEW vw_PropertyMgmt_MaintenanceRequests AS
    SELECT mr.RequestID, mr.PropertyID, p.PropertyName, mr.RequestDetails, mr.RequestDate, mr.Status
    FROM MaintenanceRequests mr
    JOIN Properties p ON mr.PropertyID = p.PropertyID;
GO
GRANT SELECT ON vw_PropertyMgmt_MaintenanceRequests TO PropertyMgmtDev;
GO

CREATE PROCEDURE sp_UpdatePropertyStatus
    @PropertyID INT, @NewStatus NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Properties
    SET Status = @NewStatus, ModifiedDate = GETDATE(), ModifiedBy = ORIGINAL_LOGIN()
    WHERE PropertyID = @PropertyID;
END;
GO
GRANT EXECUTE ON sp_UpdatePropertyStatus TO PropertyMgmtDev;
GO

CREATE PROCEDURE sp_AddNewProperty
    @PropertyName NVARCHAR(150), @Address NVARCHAR(255), @City NVARCHAR(100),
    @State NVARCHAR(100), @Price DECIMAL(18,2), @Status NVARCHAR(50) = 'Available'
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Properties (PropertyName, Address, City, State, Price, Status)
    VALUES (@PropertyName, @Address, @City, @State, @Price, @Status);
END;
GO
GRANT EXECUTE ON sp_AddNewProperty TO PropertyMgmtDev;
GO

CREATE PROCEDURE sp_AddMaintenanceRequest
    @PropertyID INT, @RequestDetails NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO MaintenanceRequests (PropertyID, RequestDetails, Status)
    VALUES (@PropertyID, @RequestDetails, 'Pending');
END;
GO
GRANT EXECUTE ON sp_AddMaintenanceRequest TO PropertyMgmtDev;
GO

CREATE PROCEDURE sp_UpdateMaintenanceStatus
    @RequestID INT, @NewStatus NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE MaintenanceRequests SET Status = @NewStatus WHERE RequestID = @RequestID;
END;
GO
GRANT EXECUTE ON sp_UpdateMaintenanceStatus TO PropertyMgmtDev;
GO

DENY SELECT, INSERT, UPDATE, DELETE ON Properties TO PropertyMgmtDev;
DENY SELECT, INSERT, UPDATE, DELETE ON MaintenanceRequests TO PropertyMgmtDev;
GO


/* =============================================================================
   SECTION 9: ANALYTICS - READ-ONLY, MASKED VIEWS
   Purpose: Aggregated business insight across Clients/Agents/Properties/
   Transactions without exposing raw PII. Masking (Section 6) is enforced
   automatically since AnalyticsTeam has no UNMASK permission. No write
   access at all - this role is read-only by design.
   ============================================================================= */

CREATE VIEW vw_Analytics_ClientSummary AS
    SELECT ClientID, FullName, ContactNumber, Email, RegisteredDate
    FROM Clients;
GO
GRANT SELECT ON vw_Analytics_ClientSummary TO AnalyticsTeam;
GO

CREATE VIEW vw_Analytics_AgentPerformance AS
    SELECT
        a.AgentID, a.FullName, a.Email,
        COUNT(t.TransactionID) AS TotalTransactions,
        SUM(t.Amount)          AS TotalSalesValue
    FROM Agents a
    LEFT JOIN Transactions t ON a.AgentID = t.AgentID
    GROUP BY a.AgentID, a.FullName, a.Email;
GO
GRANT SELECT ON vw_Analytics_AgentPerformance TO AnalyticsTeam;
GO

CREATE VIEW vw_Analytics_PropertyMarket AS
    SELECT City, State, Status,
           COUNT(*)       AS PropertyCount,
           AVG(Price)     AS AveragePrice,
           MIN(Price)     AS MinPrice,
           MAX(Price)     AS MaxPrice
    FROM Properties
    GROUP BY City, State, Status;
GO
GRANT SELECT ON vw_Analytics_PropertyMarket TO AnalyticsTeam;
GO

CREATE VIEW vw_Analytics_MonthlyTransactions AS
    SELECT
        YEAR(TransactionDate)  AS TransactionYear,
        MONTH(TransactionDate) AS TransactionMonth,
        TransactionType,
        COUNT(*)      AS TransactionCount,
        SUM(Amount)   AS TotalAmount
    FROM Transactions
    GROUP BY YEAR(TransactionDate), MONTH(TransactionDate), TransactionType;
GO
GRANT SELECT ON vw_Analytics_MonthlyTransactions TO AnalyticsTeam;
GO

DENY SELECT, INSERT, UPDATE, DELETE ON Clients TO AnalyticsTeam;
DENY SELECT, INSERT, UPDATE, DELETE ON Agents TO AnalyticsTeam;
DENY SELECT, INSERT, UPDATE, DELETE ON Properties TO AnalyticsTeam;
DENY SELECT, INSERT, UPDATE, DELETE ON Transactions TO AnalyticsTeam;
GO


/* =============================================================================
   SECTION 10: DATABASE ADMINISTRATION - BROAD ACCESS, FULL ACCOUNTABILITY
   Purpose: Unlike developer roles (access only through views/procedures),
   DBAdminRole needs broad direct access to perform maintenance, backups,
   and troubleshooting across the whole system. This elevated privilege is
   balanced by full accountability - every DBA action is captured by the
   Server/Database Auditing (Section 14) and Triggers (Section 16), so no
   one is exempt from oversight regardless of privilege level. Even here,
   PasswordHash values remain irreversible ciphertext (Section 3) - broad
   access does not mean unlimited visibility into every kind of data.
   ============================================================================= */

GRANT SELECT, INSERT, UPDATE, DELETE ON Properties           TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Clients               TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Agents                TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Transactions          TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON MaintenanceRequests   TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Departments           TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Users                 TO DBAdminRole;
GRANT BACKUP DATABASE TO DBAdminRole;
GRANT BACKUP LOG TO DBAdminRole;
GRANT EXECUTE ON dbo.sp_UnlockAppUser TO DBAdminRole;
GO

GRANT CONTROL ON CERTIFICATE::PIICert TO DBAdminRole;
GRANT VIEW DEFINITION ON SYMMETRIC KEY::PIIKey TO DBAdminRole;
GRANT UNMASK TO DBAdminRole;   -- confirmed idempotent (already granted in Section 6)
GO
-- Note: GRANT SELECT ON AuditLog TO DBAdminRole is issued in Section 16,
-- once the AuditLog table has been created.


/* =============================================================================
   SECTION 11: AGENT OPERATIONS DEVELOPMENT - VIEWS, PROCEDURES, ACCESS
   Purpose: Mirrors the Client Portal pattern (Section 7) applied to Agents
   and Transactions - basic view, decrypted-read procedure, write
   procedures, direct table access denied.
   ============================================================================= */

CREATE VIEW vw_AgentOps_Agents AS
    SELECT
        a.AgentID, a.FullName, a.CommissionRate, a.JoinedDate,
        COUNT(t.TransactionID) AS TotalTransactions
    FROM Agents a
    LEFT JOIN Transactions t ON a.AgentID = t.AgentID
    GROUP BY a.AgentID, a.FullName, a.CommissionRate, a.JoinedDate;
GO
GRANT SELECT ON vw_AgentOps_Agents TO AgentOpsDev;
GO

CREATE VIEW vw_AgentOps_Transactions AS
    SELECT
        t.TransactionID, t.PropertyID, p.PropertyName, t.ClientID, t.AgentID,
        a.FullName AS AgentName, t.TransactionType, t.TransactionDate, t.Amount
    FROM Transactions t
    JOIN Properties p ON t.PropertyID = p.PropertyID
    JOIN Agents a ON t.AgentID = a.AgentID;
GO
GRANT SELECT ON vw_AgentOps_Transactions TO AgentOpsDev;
GO

-- Aggregated performance view avoids exposing client PII while supporting
-- agent monitoring and commission review.
CREATE VIEW vw_AgentOps_PerformanceSummary AS
    SELECT a.AgentID,a.FullName AS AgentName,
           COUNT(t.TransactionID) AS TotalTransactions,
           ISNULL(SUM(t.Amount),0) AS TotalTransactionAmount,
           ISNULL(AVG(t.Amount),0) AS AverageTransactionAmount
    FROM Agents a
    LEFT JOIN Transactions t ON t.AgentID=a.AgentID
    GROUP BY a.AgentID,a.FullName;
GO
GRANT SELECT ON vw_AgentOps_PerformanceSummary TO AgentOpsDev;
GO

CREATE PROCEDURE sp_GetAgentContactInfo
    @AgentID INT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
        SELECT AgentID,FullName,
               CONVERT(NVARCHAR(20),DECRYPTBYKEY(ContactNumber_Enc)) AS ContactNumber,
               CONVERT(NVARCHAR(100),DECRYPTBYKEY(Email_Enc)) AS Email
        FROM Agents WHERE AgentID=@AgentID;
        CLOSE SYMMETRIC KEY PIIKey;
    END TRY
    BEGIN CATCH
        IF EXISTS(SELECT 1 FROM sys.openkeys WHERE key_name=N'PIIKey')
            CLOSE SYMMETRIC KEY PIIKey;
        THROW;
    END CATCH
END;
GO
GRANT EXECUTE ON sp_GetAgentContactInfo TO AgentOpsDev;
GO

CREATE PROCEDURE sp_RegisterNewAgent
    @FullName NVARCHAR(100), @ContactNumber NVARCHAR(20),
    @Email NVARCHAR(100), @CommissionRate DECIMAL(5,2)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    IF @CommissionRate NOT BETWEEN 0 AND 100
        THROW 50030, 'Commission rate must be between 0 and 100.', 1;

    BEGIN TRY
        OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
        INSERT INTO Agents (FullName,ContactNumber,Email,CommissionRate,ContactNumber_Enc,Email_Enc)
        VALUES(@FullName,@ContactNumber,@Email,@CommissionRate,
               ENCRYPTBYKEY(KEY_GUID('PIIKey'),@ContactNumber),
               ENCRYPTBYKEY(KEY_GUID('PIIKey'),@Email));
        CLOSE SYMMETRIC KEY PIIKey;
    END TRY
    BEGIN CATCH
        IF EXISTS(SELECT 1 FROM sys.openkeys WHERE key_name=N'PIIKey')
            CLOSE SYMMETRIC KEY PIIKey;
        THROW;
    END CATCH
END;
GO
GRANT EXECUTE ON sp_RegisterNewAgent TO AgentOpsDev;
GO

CREATE PROCEDURE sp_AddTransaction
    @PropertyID INT, @ClientID INT, @AgentID INT,
    @TransactionType NVARCHAR(50), @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @TransactionType NOT IN (N'Sale',N'Rent')
        THROW 50031, 'Transaction type must be Sale or Rent.', 1;
    IF @Amount<=0
        THROW 50032, 'Transaction amount must be greater than zero.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        -- Serialise the availability check so two sessions cannot transact the
        -- same property simultaneously.
        IF NOT EXISTS(SELECT 1 FROM Properties WITH(UPDLOCK,HOLDLOCK)
                      WHERE PropertyID=@PropertyID AND Status=N'Available')
            THROW 50033, 'Property is not available for a new transaction.', 1;

        INSERT INTO Transactions(PropertyID,ClientID,AgentID,TransactionType,Amount)
        VALUES(@PropertyID,@ClientID,@AgentID,@TransactionType,@Amount);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
GRANT EXECUTE ON sp_AddTransaction TO AgentOpsDev;
GO

CREATE PROCEDURE sp_UpdateAgentCommission
    @AgentID INT,
    @NewCommissionRate DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF @NewCommissionRate NOT BETWEEN 0 AND 100
        THROW 50034, 'Commission rate must be between 0 and 100.', 1;
    IF NOT EXISTS(SELECT 1 FROM Agents WHERE AgentID=@AgentID)
        THROW 50035, 'Agent does not exist.', 1;
    IF EXISTS(SELECT 1 FROM Agents WHERE AgentID=@AgentID AND CommissionRate=@NewCommissionRate)
        THROW 50036, 'New commission rate is unchanged.', 1;

    UPDATE Agents SET CommissionRate=@NewCommissionRate WHERE AgentID=@AgentID;
END;
GO
GRANT EXECUTE ON sp_UpdateAgentCommission TO AgentOpsDev;
GO

DENY SELECT, INSERT, UPDATE, DELETE ON Agents TO AgentOpsDev;
DENY SELECT, INSERT, UPDATE, DELETE ON Transactions TO AgentOpsDev;
GO




/* =============================================================================
   11.7 AGENT OPERATIONS - AGENT COMMISSION HISTORY TABLE
   Purpose:
   Stores commission rate changes for accountability and audit support.
   This supports traceability when an agent's commission rate is changed.
   ============================================================================= */

CREATE TABLE AgentCommissionHistory
(
    CommissionHistoryID INT IDENTITY(1,1) PRIMARY KEY,

    AgentID INT NOT NULL,

    OldCommissionRate DECIMAL(5,2) NULL,

    NewCommissionRate DECIMAL(5,2) NULL,

    ChangedBy NVARCHAR(100) NOT NULL
        CONSTRAINT DF_AgentCommissionHistory_ChangedBy
        DEFAULT ORIGINAL_LOGIN(),

    ChangedDate DATETIME NOT NULL
        CONSTRAINT DF_AgentCommissionHistory_ChangedDate
        DEFAULT GETDATE(),

    Remarks NVARCHAR(255) NULL,

    CONSTRAINT FK_AgentCommissionHistory_Agents
        FOREIGN KEY (AgentID)
        REFERENCES Agents(AgentID)
);
GO

GRANT SELECT ON AgentCommissionHistory TO AgentOpsDev;
GO


/* =============================================================================
   11.8 AGENT OPERATIONS - COMMISSION UPDATE TRIGGER
   Purpose:
   Automatically records old and new commission rates whenever an agent's
   commission rate is updated.
   ============================================================================= */

CREATE TRIGGER trg_AgentCommission_UpdateHistory
ON Agents
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AgentCommissionHistory
    (
        AgentID,
        OldCommissionRate,
        NewCommissionRate,
        ChangedBy,
        Remarks
    )
    SELECT
        i.AgentID,
        d.CommissionRate,
        i.CommissionRate,
        ORIGINAL_LOGIN(),
        'Agent commission rate updated.'
    FROM inserted i
    INNER JOIN deleted d
        ON i.AgentID = d.AgentID
    WHERE ISNULL(i.CommissionRate, 0) <> ISNULL(d.CommissionRate, 0);
END;
GO


/* =============================================================================
   11.9 AGENT OPERATIONS - ACCESS CONTROL
   Purpose:
   AgentOpsDev is only allowed to access approved views and stored
   procedures. Direct access to sensitive base tables is denied.
   ============================================================================= */

DENY SELECT, INSERT, UPDATE, DELETE ON Agents TO AgentOpsDev;
DENY SELECT, INSERT, UPDATE, DELETE ON Transactions TO AgentOpsDev;
DENY SELECT, INSERT, UPDATE, DELETE ON Clients TO AgentOpsDev;
DENY SELECT, INSERT, UPDATE, DELETE ON Users TO AgentOpsDev;
GO

/* =============================================================================
   SECTION 12: TRANSPARENT DATA ENCRYPTION (TDE) - BONUS
   Purpose: Column-level encryption (Section 5) protects specific PII
   fields and remains reversible on demand for legitimate use. TDE is a
   different, complementary layer: it encrypts the ENTIRE database file and
   all its backups at rest, so that even a stolen .mdf/.bak file is
   unreadable without the certificate - protecting everything, including
   data that was never individually flagged as sensitive.
   Limitation: TDE support depends on SQL Server edition/version. If the lab
   edition does not support it, document that limitation while retaining the
   tested column-level AES-256 encryption controls.
   ============================================================================= */

USE master;
GO

-- TDE certificate is stored in master. Ensure master has its own database
-- master key first; this key is separate from GreenAcresEMS_Final's PII key.
IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys WHERE name=N'##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD='MasterTDE@2026Strong!';
GO
CREATE CERTIFICATE TDECert WITH SUBJECT = 'Certificate for Transparent Data Encryption - GreenAcresEMS_Final';
GO

USE GreenAcresEMS_Final;
GO
BEGIN TRY
    CREATE DATABASE ENCRYPTION KEY
        WITH ALGORITHM = AES_256
        ENCRYPTION BY SERVER CERTIFICATE TDECert;

    ALTER DATABASE GreenAcresEMS_Final SET ENCRYPTION ON;

    PRINT 'TDE enabled successfully for GreenAcresEMS_Final.';
END TRY
BEGIN CATCH
    /* TDE availability depends on the installed SQL Server edition/version.
       A TDE failure does not weaken the separate AES-256 column encryption
       protecting client and agent PII in Section 5. */
    PRINT 'TDE not supported or could not be enabled on this SQL Server edition. Column-level encryption remains active.';
    PRINT 'TDE diagnostic: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Verify TDE is active
SELECT name, is_encrypted FROM sys.databases WHERE name = 'GreenAcresEMS_Final';
GO


/* =============================================================================
   SECTION 13: BACKUPS (Availability)
   Purpose: Full, Differential, and Transaction Log backups, plus backups of
   BOTH database master keys and BOTH certificates used above. Losing PIICert makes column-encrypted PII
   permanently unrecoverable; losing TDECert makes the ENTIRE database
   permanently unrecoverable - even with a valid, otherwise-intact database
   backup file, because the decryption key would no longer exist anywhere.
   >>> CHANGE ME - update paths to folders that exist on your machine.
   ============================================================================= */

BACKUP DATABASE GreenAcresEMS_Final
    TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Full.bak'
    WITH INIT, CHECKSUM, NAME = 'GreenAcresEMS_Final-Full Database Backup';
GO

BACKUP DATABASE GreenAcresEMS_Final
    TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Diff.bak'
    WITH DIFFERENTIAL, INIT, CHECKSUM, NAME = 'GreenAcresEMS_Final-Differential Backup';
GO

BACKUP LOG GreenAcresEMS_Final
    TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Log.trn'
    WITH INIT, CHECKSUM, NAME = 'GreenAcresEMS_Final-Transaction Log Backup';
GO

-- Back up this database's DMK, which protects PIICert and the PIIKey hierarchy.
-- Store the backup file and its password separately from the database backups.
BEGIN TRY
    BACKUP MASTER KEY
        TO FILE = 'C:\GreenAcresBackups\GreenAcresEMS_Final_PII_DMK.key'
        ENCRYPTION BY PASSWORD = 'GreenAcresPIIDMKBackup@2026Strong!';
    PRINT 'GreenAcresEMS_Final database master key backup created successfully.';
END TRY
BEGIN CATCH
    PRINT 'WARNING - GreenAcresEMS_Final master key backup was not created. Ensure the folder is writable and remove any old .key file before the final run.';
    PRINT 'DMK backup diagnostic: ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    BACKUP CERTIFICATE PIICert
        TO FILE = 'C:\GreenAcresBackups\PIICert.cer'
        WITH PRIVATE KEY (
            FILE = 'C:\GreenAcresBackups\PIICert.pvk',
            ENCRYPTION BY PASSWORD = 'PIICertBackup@2026Strong!'
        );
    PRINT 'PII certificate and private key backup created successfully.';
END TRY
BEGIN CATCH
    PRINT 'WARNING - PIICert backup was not created. Ensure the folder is writable and remove old PIICert backup files before the final run.';
    PRINT 'PIICert backup diagnostic: ' + ERROR_MESSAGE();
END CATCH;
GO

USE master;
GO
BEGIN TRY
    BACKUP MASTER KEY
        TO FILE='C:\GreenAcresBackups\master_TDE_DMK.key'
        ENCRYPTION BY PASSWORD='MasterTDEBackup@2026Strong!';
    PRINT 'master database master key backup created successfully.';
END TRY
BEGIN CATCH
    PRINT 'WARNING - master database master key backup was not created. Ensure the folder is writable and remove any old .key file before the final run.';
    PRINT 'master DMK backup diagnostic: ' + ERROR_MESSAGE();
END CATCH;
GO
BEGIN TRY
    BACKUP CERTIFICATE TDECert
        TO FILE = 'C:\GreenAcresBackups\TDECert.cer'
        WITH PRIVATE KEY (
            FILE = 'C:\GreenAcresBackups\TDECert.pvk',
            ENCRYPTION BY PASSWORD = 'TDECertBackup@2026Strong!'
        );
    PRINT 'TDE certificate and private key backup created successfully.';
END TRY
BEGIN CATCH
    PRINT 'WARNING - TDECert backup was not created. Ensure the folder is writable and remove old TDECert backup files before the final run.';
    PRINT 'TDECert backup diagnostic: ' + ERROR_MESSAGE();
END CATCH;
GO
USE GreenAcresEMS_Final;
GO

-- Verify backup history
SELECT
    bs.database_name, bs.backup_start_date, bs.backup_finish_date,
    CASE bs.type WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction Log' END AS BackupType,
    bmf.physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'GreenAcresEMS_Final'
ORDER BY bs.backup_start_date DESC;
GO

-- Restore test: prove the Full backup is genuinely restorable, to a
-- differently-named database so the live system is never put at risk.
RESTORE FILELISTONLY FROM DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Full.bak';
GO

RESTORE DATABASE GreenAcresEMS_Final_RestoreTest
    FROM DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Full.bak'
    WITH
        MOVE 'GreenAcresEMS_Final'     TO 'C:\GreenAcresBackups\GreenAcresEMS_Final_RestoreTest.mdf',
        MOVE 'GreenAcresEMS_Final_log' TO 'C:\GreenAcresBackups\GreenAcresEMS_Final_RestoreTest_log.ldf',
        RECOVERY;
GO

USE GreenAcresEMS_Final_RestoreTest;
GO
SELECT * FROM Clients;
SELECT * FROM Properties;
GO

USE GreenAcresEMS_Final;
GO

-- Clean up the restore-test database once verified
USE master;
GO
DROP DATABASE GreenAcresEMS_Final_RestoreTest;
GO
USE GreenAcresEMS_Final;
GO


/* =============================================================================
   SECTION 14: SERVER AUDITING AND DATABASE AUDITING
   Purpose: Server Audit captures instance-wide security events (failed
   logins, role membership changes). Database Audit Specification captures
   activity on specific sensitive objects within GreenAcresEMS_Final (who read or
   changed Clients/Agents PII, or changed a Property record).
   >>> CHANGE ME - update the audit folder path to one that exists.
   ============================================================================= */

USE master;
GO

CREATE SERVER AUDIT GreenAcres_ServerAudit
    TO FILE (FILEPATH = 'C:\GreenAcresAudits\');
GO
ALTER SERVER AUDIT GreenAcres_ServerAudit WITH (STATE = ON);
GO

CREATE SERVER AUDIT SPECIFICATION GreenAcres_ServerAuditSpec
    FOR SERVER AUDIT GreenAcres_ServerAudit
    ADD (FAILED_LOGIN_GROUP),
    ADD (SUCCESSFUL_LOGIN_GROUP),
    ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP)
    WITH (STATE = ON);
GO

-- Server-scoped, read-only permission needed to review SQL Server Audit.
GRANT VIEW SERVER SECURITY AUDIT TO security_auditor_login;
GO

USE GreenAcresEMS_Final;
GO

CREATE DATABASE AUDIT SPECIFICATION GreenAcres_DBAuditSpec
    FOR SERVER AUDIT GreenAcres_ServerAudit
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Clients BY PUBLIC),
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Agents  BY PUBLIC),
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Transactions BY PUBLIC),
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.MaintenanceRequests BY PUBLIC),
    ADD (UPDATE ON dbo.Properties BY PUBLIC),
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),
    ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
    -- Records privileged changes to database objects, including disabling,
    -- altering or dropping an audit-protection trigger.
    ADD (DATABASE_OBJECT_CHANGE_GROUP)
    WITH (STATE = ON);
GO

-- Verification: generate an event, then read the audit file
SELECT ClientID, FullName FROM Clients;
GO

SELECT
    event_time, action_id, succeeded, server_principal_name,
    database_name, object_name, statement
FROM sys.fn_get_audit_file('C:\GreenAcresAudits\*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id IN ('SL', 'IN', 'UP', 'DL', 'LGIF')  -- Select, Insert, Update, Delete, Failed Login
ORDER BY event_time DESC;


/* =============================================================================
   SECTION 15: SERVER-LEVEL LOGON TRIGGER - BONUS
   Purpose: A third, distinct trigger category alongside the DML triggers in
   Section 16. A LOGON trigger fires after successful authentication and records
   who connected, when and from which host. Failed authentication does not fire
   a LOGON trigger; FAILED_LOGIN_GROUP in SQL Server Audit records failures.
   ============================================================================= */

USE master;
GO

CREATE TABLE dbo.LoginAudit (
    LoginAuditID INT IDENTITY(1,1) PRIMARY KEY,
    LoginName    NVARCHAR(100),
    LoginTime    DATETIME DEFAULT GETDATE(),
    ClientHost   NVARCHAR(100)
);
GO

-- A database user is required in master before object-level SELECT can be
-- granted to the existing server login.
CREATE USER security_auditor_login FOR LOGIN security_auditor_login;
GO
GRANT SELECT ON dbo.LoginAudit TO security_auditor_login;
DENY INSERT, UPDATE, DELETE ON dbo.LoginAudit TO security_auditor_login;
GO

-- >>> CHANGE ME: Replace the following administrator login if this script
-- is deployed on a different SQL Server computer.
CREATE TRIGGER trg_LogonAudit
ON ALL SERVER
WITH EXECUTE AS 'DESKTOP-JFIFOB9\pc'
FOR LOGON
AS
BEGIN
    SET NOCOUNT ON;

    -- Execute under the deployment administrator because ordinary developer
    -- logins do not have INSERT permission on master.dbo.LoginAudit.
    BEGIN TRY
        INSERT INTO master.dbo.LoginAudit
            (LoginName, ClientHost)
        VALUES
            (ORIGINAL_LOGIN(), HOST_NAME());
    END TRY
    BEGIN CATCH
        -- An audit insertion failure must not block legitimate connections.
        RETURN;
    END CATCH;
END;
GO

USE GreenAcresEMS_Final;
GO

-- Verify: check recent logon activity
SELECT TOP 20 * FROM master.dbo.LoginAudit ORDER BY LoginTime DESC;
GO


/* =============================================================================
   SECTION 16: DML TRIGGERS - AUDITING AND OPERATIONAL
   Purpose: Two categories, as required by the assignment. Auditing triggers
   log every change into AuditLog (before/after JSON snapshots, independent
   of the engine-level Server/Database Audit in Section 14). Operational
   triggers enforce business rules automatically, regardless of which role
   or procedure performs the action.
   ============================================================================= */

CREATE TABLE AuditLog (
    AuditID     INT IDENTITY(1,1) PRIMARY KEY,
    TableName   NVARCHAR(100),
    Operation   NVARCHAR(10),
    RecordID    INT,
    ChangedBy   NVARCHAR(100) DEFAULT ORIGINAL_LOGIN(),
    ChangedDate DATETIME DEFAULT GETDATE(),
    OldValue    NVARCHAR(MAX),
    NewValue    NVARCHAR(MAX),
    CONSTRAINT CK_AuditLog_Operation CHECK(Operation IN ('INSERT','UPDATE','DELETE'))
);
GO
GRANT SELECT ON AuditLog TO DBAdminRole;
GRANT SELECT ON AuditLog TO SecurityAuditor;
DENY INSERT, UPDATE, DELETE ON AuditLog TO SecurityAuditor;
GRANT SELECT ON AgentCommissionHistory TO SecurityAuditor;
DENY INSERT, UPDATE, DELETE ON AgentCommissionHistory TO SecurityAuditor;
GRANT VIEW DEFINITION TO SecurityAuditor;

-- The auditor reviews evidence only and cannot read or modify operational PII.
DENY SELECT, INSERT, UPDATE, DELETE ON Clients TO SecurityAuditor;
DENY SELECT, INSERT, UPDATE, DELETE ON Agents TO SecurityAuditor;
DENY SELECT, INSERT, UPDATE, DELETE ON Transactions TO SecurityAuditor;
DENY INSERT, UPDATE, DELETE ON Properties TO SecurityAuditor;
DENY INSERT, UPDATE, DELETE ON MaintenanceRequests TO SecurityAuditor;
DENY SELECT, INSERT, UPDATE, DELETE ON Users TO SecurityAuditor;
GO

CREATE INDEX IX_AuditLog_Table_ChangedDate
ON AuditLog(TableName,ChangedDate DESC);
GO

-- 16.1 Auditing trigger: Properties (full CRUD). The original trigger name is
-- retained, while row-specific operation detection also supports MERGE batches.
CREATE TRIGGER trg_Properties_AuditUpdate
ON Properties AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (TableName, Operation, RecordID, OldValue, NewValue)
    SELECT
        'Properties',
        CASE WHEN i.PropertyID IS NOT NULL AND d.PropertyID IS NOT NULL THEN 'UPDATE'
             WHEN i.PropertyID IS NOT NULL THEN 'INSERT' ELSE 'DELETE' END,
        COALESCE(i.PropertyID,d.PropertyID),
        CASE WHEN d.PropertyID IS NULL THEN NULL
             ELSE CONCAT('Status=',d.Status,'; Price=',d.Price) END,
        CASE WHEN i.PropertyID IS NULL THEN NULL
             ELSE CONCAT('Status=',i.Status,'; Price=',i.Price) END
    FROM inserted i
    FULL JOIN deleted d ON i.PropertyID=d.PropertyID;
END;
GO

-- 16.2 Auditing trigger: Clients (INSERT/UPDATE/DELETE). The original trigger
-- name is retained, but coverage is expanded without copying contact PII.
CREATE TRIGGER trg_Clients_AuditInsert
ON Clients AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operation NVARCHAR(10)=
        CASE WHEN EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE'
             WHEN EXISTS(SELECT 1 FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    INSERT INTO AuditLog(TableName,Operation,RecordID,OldValue,NewValue)
    SELECT 'Clients',@Operation,COALESCE(i.ClientID,d.ClientID),
           CASE WHEN d.ClientID IS NULL THEN NULL ELSE CONCAT('Name=',d.FullName) END,
           CASE WHEN i.ClientID IS NULL THEN NULL ELSE CONCAT('Name=',i.FullName) END
    FROM inserted i FULL JOIN deleted d ON i.ClientID=d.ClientID;
END;
GO

-- 16.3 Auditing trigger: Agents (INSERT/UPDATE/DELETE). Contact details and
-- commission values are not duplicated into the general audit table.
CREATE TRIGGER trg_Agents_AuditInsert
ON Agents AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operation NVARCHAR(10)=
        CASE WHEN EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE'
             WHEN EXISTS(SELECT 1 FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    INSERT INTO AuditLog(TableName,Operation,RecordID,OldValue,NewValue)
    SELECT 'Agents',@Operation,COALESCE(i.AgentID,d.AgentID),
           CASE WHEN d.AgentID IS NULL THEN NULL ELSE CONCAT('Name=',d.FullName,'; Commission=[PROTECTED]') END,
           CASE WHEN i.AgentID IS NULL THEN NULL ELSE CONCAT('Name=',i.FullName,'; Commission=[PROTECTED]') END
    FROM inserted i FULL JOIN deleted d ON i.AgentID=d.AgentID;
END;
GO

-- 16.4 Auditing trigger: Transactions (INSERT/UPDATE/DELETE). Financial
-- changes remain traceable while Amount is redacted from AuditLog.
CREATE TRIGGER trg_Transactions_AuditInsert
ON Transactions AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operation NVARCHAR(10)=
        CASE WHEN EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE'
             WHEN EXISTS(SELECT 1 FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    INSERT INTO AuditLog(TableName,Operation,RecordID,OldValue,NewValue)
    SELECT 'Transactions',@Operation,COALESCE(i.TransactionID,d.TransactionID),
           CASE WHEN d.TransactionID IS NULL THEN NULL ELSE CONCAT('Type=',d.TransactionType,'; Amount=[PROTECTED]') END,
           CASE WHEN i.TransactionID IS NULL THEN NULL ELSE CONCAT('Type=',i.TransactionType,'; Amount=[PROTECTED]') END
    FROM inserted i FULL JOIN deleted d ON i.TransactionID=d.TransactionID;
END;
GO

-- 16.5 Auditing trigger: MaintenanceRequests (full CRUD). RequestDetails is
-- intentionally excluded so free-text operational content is not duplicated
-- into a differently governed audit store.
CREATE TRIGGER trg_MaintenanceRequests_Audit
ON MaintenanceRequests AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog(TableName,Operation,RecordID,OldValue,NewValue)
    SELECT 'MaintenanceRequests',
           CASE WHEN i.RequestID IS NOT NULL AND d.RequestID IS NOT NULL THEN 'UPDATE'
                WHEN i.RequestID IS NOT NULL THEN 'INSERT' ELSE 'DELETE' END,
           COALESCE(i.RequestID,d.RequestID),
           CASE WHEN d.RequestID IS NULL THEN NULL ELSE CONCAT('Status=',d.Status) END,
           CASE WHEN i.RequestID IS NULL THEN NULL ELSE CONCAT('Status=',i.Status) END
    FROM inserted i
    FULL JOIN deleted d ON i.RequestID=d.RequestID;
END;
GO

-- Bonus integrity control: audit history is append-only for ordinary users.
-- A sysadmin can still disable the trigger, so this is described as DML tamper
-- resistance rather than absolute immutability. DATABASE_OBJECT_CHANGE_GROUP
-- in Section 14 records privileged attempts to alter or disable this control.
CREATE TRIGGER trg_AuditLog_AppendOnly
ON AuditLog
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50060, 'AuditLog is append-only; UPDATE and DELETE are prohibited.', 1;
END;
GO

-- 16.6 Operational trigger: auto-update Property status on a new transaction
CREATE TRIGGER trg_Transaction_UpdatePropertyStatus
ON Transactions AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET p.Status = 'Sold', p.ModifiedDate = GETDATE(), p.ModifiedBy = ORIGINAL_LOGIN()
    FROM Properties p JOIN inserted i ON p.PropertyID = i.PropertyID
    WHERE i.TransactionType = 'Sale';

    UPDATE p
    SET p.Status = 'Rented', p.ModifiedDate = GETDATE(), p.ModifiedBy = ORIGINAL_LOGIN()
    FROM Properties p JOIN inserted i ON p.PropertyID = i.PropertyID
    WHERE i.TransactionType = 'Rent';
END;
GO

-- 16.7 Operational trigger: block maintenance requests on a Sold property
CREATE TRIGGER trg_MaintenanceRequest_PreventOnSoldProperty
ON MaintenanceRequests INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN Properties p ON i.PropertyID = p.PropertyID
        WHERE p.Status = 'Sold'
    )
    BEGIN
        RAISERROR('Cannot add a maintenance request for a property that has already been Sold.', 16, 1);
        RETURN;
    END
    INSERT INTO MaintenanceRequests (PropertyID, RequestDetails, Status)
    SELECT PropertyID, RequestDetails, Status FROM inserted;
END;
GO


/* =============================================================================
   SECTION 17: ROW-LEVEL SECURITY - BONUS
   Purpose: Beyond column masking, restrict which ROWS of Transactions are
   visible depending on the caller's role - only Analytics and DBA (and the
   schema owner) can see transaction rows via direct query. Every other
   principal already only interacts through the views/procedures in
   Sections 7-11; this is an additional defense-in-depth layer underneath
   those, in case a future object were ever mistakenly granted broader
   access than intended.
   ============================================================================= */

-- Create the predicate before the policy so a fresh database build succeeds.
-- This is role-based row visibility: eligible roles see rows; other users see
-- none. It is defence in depth beneath the normal view/procedure permissions.
CREATE FUNCTION dbo.fn_TransactionAccessPredicate(@AgentID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS AccessResult
       WHERE IS_MEMBER('DBAdminRole') = 1
          OR IS_MEMBER('AnalyticsTeam') = 1
          OR IS_MEMBER('AgentOpsDev') = 1
          OR USER_NAME() = 'dbo';
GO

CREATE SECURITY POLICY TransactionAccessPolicy
    ADD FILTER PREDICATE dbo.fn_TransactionAccessPredicate(AgentID) ON dbo.Transactions,
    ADD BLOCK PREDICATE dbo.fn_TransactionAccessPredicate(AgentID) ON dbo.Transactions AFTER INSERT
    WITH (STATE = ON);
GO


/* =============================================================================
   SECTION 18: LEAST-PRIVILEGE SELF-CHECK
   Purpose: A self-auditing query proving the Principle of Least Privilege
   was actually applied, not just claimed - developer roles should show
   mostly DENY on base tables with a small number of GRANTs (limited to
   their own views/procedures), while DBAdminRole should show the opposite
   pattern (broad GRANT). This is a genuinely useful piece of evidence for
   the Permission Management section of the report.
   ============================================================================= */

SELECT
    dp.name AS RoleName,
    SUM(CASE WHEN perm.state_desc = 'GRANT' THEN 1 ELSE 0 END) AS GrantCount,
    SUM(CASE WHEN perm.state_desc = 'DENY'  THEN 1 ELSE 0 END) AS DenyCount
FROM sys.database_permissions perm
JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
WHERE dp.type = 'R'
  AND dp.name IN ('PropertyMgmtDev','ClientPortalDev','AnalyticsTeam','DBAdminRole','AgentOpsDev','SecurityAuditor')
GROUP BY dp.name
ORDER BY dp.name;
GO


/* =============================================================================
   SECTION 19: VERIFICATION TESTS
   The original embedded tests were moved to DBS_TestCases_Group_19.sql.
   Keeping expected permission failures outside the implementation prevents
   them from interrupting a clean build and makes test evidence repeatable.
   ============================================================================= */


/* =============================================================================
   SECTION 20: DOCUMENTATION QUERIES
   Purpose: Generate the Data Dictionary and Authorization Matrix directly
   from the live database, for inclusion in the written report.
   ============================================================================= */

-- 20.1 Data Dictionary
SELECT
    t.name AS TableName, c.name AS ColumnName, ty.name AS DataType,
    c.max_length AS MaxLength, c.is_nullable AS IsNullable,
    CASE WHEN pk.column_id IS NOT NULL THEN 'PK' ELSE '' END AS KeyType
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.index_columns ic
    JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1
) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
WHERE t.name IN ('Properties','Clients','Agents','Transactions','MaintenanceRequests',
                 'Departments','Users','AgentCommissionHistory','AuditLog')
ORDER BY t.name, c.column_id;
GO

-- 20.2 Authorization Matrix
SELECT
    dp.name AS RoleOrUser,
    ISNULL(o.name, 'N/A - Certificate/Key') AS ObjectName,
    o.type_desc AS ObjectType,
    perm.permission_name AS Permission,
    perm.state_desc AS GrantOrDeny
FROM sys.database_permissions perm
JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o ON perm.major_id = o.object_id
WHERE dp.type = 'R'
ORDER BY dp.name, o.name, perm.permission_name;
GO

--20.3 Agent Operations Permission Evidence
SELECT
    dp.name AS RoleOrUser,
    ISNULL(o.name, 'N/A') AS ObjectName,
    o.type_desc AS ObjectType,
    perm.permission_name AS Permission,
    perm.state_desc AS GrantOrDeny
FROM sys.database_permissions perm
JOIN sys.database_principals dp
    ON perm.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o
    ON perm.major_id = o.object_id
WHERE dp.name = 'AgentOpsDev'
ORDER BY o.name, perm.permission_name;
GO

-- 20.4 Data Protection Coverage Summary
-- Quantifies implemented controls for report evidence. Classification metadata
-- is queried dynamically only where the catalog view is supported.
DECLARE @CoverageMajorVersion INT =
    CAST(SERVERPROPERTY('ProductMajorVersion') AS INT);

IF @CoverageMajorVersion >= 15
BEGIN
    EXEC sys.sp_executesql N'
        SELECT
            (SELECT COUNT(*) FROM sys.masked_columns) AS MaskedColumns,
            (SELECT COUNT(*) FROM sys.sensitivity_classifications) AS ClassifiedColumns,
            (SELECT COUNT(*)
             FROM sys.columns
             WHERE object_id IN (OBJECT_ID(''dbo.Clients''),OBJECT_ID(''dbo.Agents''))
               AND name IN (''ContactNumber_Enc'',''Email_Enc'',''Address_Enc''))
                AS DefinedEncryptedColumns,
            (SELECT is_encrypted
             FROM sys.databases
             WHERE name=''GreenAcresEMS_Final'') AS TDEActive,
            CAST(''SQL Server sensitivity classification supported'' AS NVARCHAR(100))
                AS ClassificationStatus;
    ';
END
ELSE
BEGIN
    SELECT
        (SELECT COUNT(*) FROM sys.masked_columns) AS MaskedColumns,
        CAST(NULL AS INT) AS ClassifiedColumns,
        (SELECT COUNT(*)
         FROM sys.columns
         WHERE object_id IN (OBJECT_ID('dbo.Clients'),OBJECT_ID('dbo.Agents'))
           AND name IN ('ContactNumber_Enc','Email_Enc','Address_Enc'))
            AS DefinedEncryptedColumns,
        (SELECT is_encrypted
         FROM sys.databases
         WHERE name='GreenAcresEMS_Final') AS TDEActive,
        CAST('Sensitivity classification unavailable below SQL Server 2019'
             AS NVARCHAR(100)) AS ClassificationStatus;
END;
GO

/* =============================================================================
   SECTION 21: CLIENT EMAIL HASHING [BONUS]
   Purpose: A second, distinct application of hashing beyond passwords.
   Stores a one-way hash of each client's normalized email, enabling
   duplicate-email detection at registration WITHOUT needing to compare
   plaintext emails directly. Uses a demonstration pepper combined with the
   email before hashing - which is a different technique from the salted
   password hashing in Section 3 (there, each user gets a unique random
   salt; here, the same pepper is deliberately reused so that hashes of
   the same email are always identical, which is required to detect
   duplicates).
   ============================================================================= */

USE GreenAcresEMS_Final;
GO

-- 20.5 Security Auditor permission evidence
SELECT dp.name AS RoleOrUser,
       ISNULL(o.name,'Database-level permission') AS ObjectName,
       o.type_desc AS ObjectType,
       perm.permission_name AS Permission,
       perm.state_desc AS GrantOrDeny
FROM sys.database_permissions perm
JOIN sys.database_principals dp ON perm.grantee_principal_id=dp.principal_id
LEFT JOIN sys.objects o ON perm.major_id=o.object_id
WHERE dp.name='SecurityAuditor'
ORDER BY o.name,perm.permission_name;
GO

-- Single source of truth for normalization and hashing. In production, the
-- pepper should be kept outside the database in a secret manager; it is inside
-- this function only so the assignment remains self-contained and testable.
CREATE FUNCTION dbo.fn_GetClientEmailHash(@Email NVARCHAR(100))
RETURNS VARBINARY(32)
WITH SCHEMABINDING
AS
BEGIN
    IF @Email IS NULL RETURN NULL;
    RETURN HASHBYTES('SHA2_256',CONVERT(VARBINARY(MAX),
           N'GreenAcresPepper2026'+LOWER(LTRIM(RTRIM(@Email)))));
END;
GO

-- 21.1: Add the EmailHash column to Clients
ALTER TABLE Clients ADD EmailHash VARBINARY(32) NULL;
GO

-- 21.2: Backfill EmailHash for existing clients
-- Normalization: lowercase + trim, so 'John@Gmail.com' and 'john@gmail.com '
-- are treated as the same email for duplicate-detection purposes.
UPDATE Clients
SET EmailHash = dbo.fn_GetClientEmailHash(Email)
WHERE Email IS NOT NULL;
GO

-- 21.3: Add a unique index on EmailHash so the database itself enforces
-- no two clients can ever share the same normalized email
CREATE UNIQUE INDEX UX_Clients_EmailHash ON Clients(EmailHash) WHERE EmailHash IS NOT NULL;
GO

-- 21.4: Update sp_RegisterNewClient to compute EmailHash and check for
-- duplicates BEFORE inserting, with a clear error message rather than
-- letting it fail on the unique index alone
ALTER PROCEDURE sp_RegisterNewClient
    @FullName NVARCHAR(100),
    @ContactNumber NVARCHAR(20),
    @Email NVARCHAR(100),
    @Address NVARCHAR(255)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmailHash VARBINARY(32)=dbo.fn_GetClientEmailHash(@Email);

    IF @EmailHash IS NULL THROW 50070, 'Email is required.', 1;
    IF EXISTS(SELECT 1 FROM Clients WHERE EmailHash=@EmailHash)
        THROW 50071, 'A client with this email address is already registered.', 1;

    BEGIN TRY
        OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
        INSERT INTO Clients(FullName,ContactNumber,Email,Address,
                            ContactNumber_Enc,Email_Enc,Address_Enc,EmailHash)
        VALUES(@FullName,@ContactNumber,@Email,@Address,
               ENCRYPTBYKEY(KEY_GUID('PIIKey'),@ContactNumber),
               ENCRYPTBYKEY(KEY_GUID('PIIKey'),@Email),
               ENCRYPTBYKEY(KEY_GUID('PIIKey'),@Address),@EmailHash);
        CLOSE SYMMETRIC KEY PIIKey;
    END TRY
    BEGIN CATCH
        IF EXISTS(SELECT 1 FROM sys.openkeys WHERE key_name=N'PIIKey')
            CLOSE SYMMETRIC KEY PIIKey;
        THROW;
    END CATCH
END;
GO

-- 21.5: Verify - EmailHash shows unreadable binary for all existing clients
SELECT ClientID, FullName, Email, EmailHash FROM Clients;
GO


/* =============================================================================
   SECTION 22: FINAL BACKUP
   Taken after every permission, trigger, audit and bonus control so the final
   submission backup reflects the complete implementation.
   ============================================================================= */
BACKUP DATABASE GreenAcresEMS_Final
    TO DISK='C:\GreenAcresBackups\GreenAcresEMS_Final_Final_Full.bak'
    WITH INIT,CHECKSUM,NAME='GreenAcresEMS_Final-Final Submission Backup';
GO

/* =============================================================================
   END OF GROUP 19 IMPLEMENTATION
   ============================================================================= */
