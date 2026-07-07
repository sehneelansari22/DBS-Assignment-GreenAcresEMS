/* =============================================================================
   GREEN ACRES REALTY - ESTATE MANAGEMENT SYSTEM (EMS)
   Database Security Assignment - CT069-3-3
   Full Implementation Script (Final, Hardened Version)

   Run this file top to bottom, in order, in SQL Server Management Studio,
   against a fresh instance. Lines marked >>> CHANGE ME require a local
   folder path to be updated before running that section.
   ============================================================================= */


/* =============================================================================
   SECTION 0: DATABASE SETUP
   ============================================================================= */

IF DB_ID('GreenAcresEMS_Final') IS NULL
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
   one-way salted hashing (SHA2_256). The salt is generated once per user
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
    PasswordSalt  UNIQUEIDENTIFIER NOT NULL,          -- generated once at creation, reused at verification
    PasswordHash  VARBINARY(64) NOT NULL,             -- SHA2_256(password + salt); irreversible
    DepartmentID  INT NOT NULL CONSTRAINT FK_Users_Department FOREIGN KEY REFERENCES Departments(DepartmentID),
    CreatedDate   DATETIME NOT NULL CONSTRAINT DF_Users_Created DEFAULT GETDATE()
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
    DECLARE @Salt UNIQUEIDENTIFIER = NEWID();
    INSERT INTO Users (Username, PasswordSalt, PasswordHash, DepartmentID)
    VALUES (
        @Username,
        @Salt,
        HASHBYTES('SHA2_256', @PlaintextPassword + CONVERT(NVARCHAR(36), @Salt)),
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
    SET @IsValid = 0;

    SELECT @IsValid = CASE
        WHEN PasswordHash = HASHBYTES('SHA2_256', @PlaintextPassword + CONVERT(NVARCHAR(36), PasswordSalt))
        THEN 1 ELSE 0 END
    FROM Users
    WHERE Username = @Username;
END;
GO

-- One application account per department, named after the staff member
-- responsible for it.
EXEC sp_CreateAppUser @Username='izzah.zulkafli', @PlaintextPassword='Izzah@2026!',  @DepartmentID=1;  -- Property Management Dev
EXEC sp_CreateAppUser @Username='sehneel.ansari', @PlaintextPassword='Sehneel@2026!',@DepartmentID=2;  -- Client Portal Dev
EXEC sp_CreateAppUser @Username='priya.suhuba',   @PlaintextPassword='Priya@2026!',  @DepartmentID=3;  -- Analytics
EXEC sp_CreateAppUser @Username='imran.amir',     @PlaintextPassword='Imran@2026!',  @DepartmentID=4;  -- Database Administration
EXEC sp_CreateAppUser @Username='lim.jiahui',     @PlaintextPassword='JiaHui@2026!', @DepartmentID=5;  -- Agent Operations Dev
GO

-- Verify: PasswordHash displays as unreadable binary - proof no plain-text
-- credential is stored anywhere in the table.
SELECT UserID, Username, PasswordHash, DepartmentID FROM Users;
GO

-- Demonstrate the verification procedure with both a correct and an
-- incorrect password, proving the hash comparison genuinely works.
DECLARE @Result BIT;

EXEC sp_VerifyAppUserLogin @Username='izzah.zulkafli', @PlaintextPassword='Izzah@2026!', @IsValid=@Result OUTPUT;
SELECT 'Correct password' AS TestCase, @Result AS IsValid;

EXEC sp_VerifyAppUserLogin @Username='izzah.zulkafli', @PlaintextPassword='WrongPassword', @IsValid=@Result OUTPUT;
SELECT 'Incorrect password' AS TestCase, @Result AS IsValid;
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
    @ClientID INT = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
    SELECT
        ClientID, FullName,
        CONVERT(NVARCHAR(20),  DECRYPTBYKEY(ContactNumber_Enc)) AS ContactNumber,
        CONVERT(NVARCHAR(100), DECRYPTBYKEY(Email_Enc))         AS Email,
        CONVERT(NVARCHAR(255), DECRYPTBYKEY(Address_Enc))       AS Address
    FROM Clients
    WHERE (@ClientID IS NULL OR ClientID = @ClientID);
    CLOSE SYMMETRIC KEY PIIKey;
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
    SET Status = @NewStatus, ModifiedDate = GETDATE(), ModifiedBy = SUSER_SNAME()
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

CREATE PROCEDURE sp_GetAgentContactInfo
    @AgentID INT = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
    SELECT
        AgentID, FullName,
        CONVERT(NVARCHAR(20),  DECRYPTBYKEY(ContactNumber_Enc)) AS ContactNumber,
        CONVERT(NVARCHAR(100), DECRYPTBYKEY(Email_Enc))         AS Email
    FROM Agents
    WHERE (@AgentID IS NULL OR AgentID = @AgentID);
    CLOSE SYMMETRIC KEY PIIKey;
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
    OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
    INSERT INTO Agents (FullName, ContactNumber, Email, CommissionRate, ContactNumber_Enc, Email_Enc)
    VALUES (
        @FullName, @ContactNumber, @Email, @CommissionRate,
        ENCRYPTBYKEY(KEY_GUID('PIIKey'), @ContactNumber),
        ENCRYPTBYKEY(KEY_GUID('PIIKey'), @Email)
    );
    CLOSE SYMMETRIC KEY PIIKey;
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
    INSERT INTO Transactions (PropertyID, ClientID, AgentID, TransactionType, Amount)
    VALUES (@PropertyID, @ClientID, @AgentID, @TransactionType, @Amount);
END;
GO
GRANT EXECUTE ON sp_AddTransaction TO AgentOpsDev;
GO

DENY SELECT, INSERT, UPDATE, DELETE ON Agents TO AgentOpsDev;
DENY SELECT, INSERT, UPDATE, DELETE ON Transactions TO AgentOpsDev;
GO


/* =============================================================================
   11.1 AGENT OPERATIONS VIEW: AGENT SUMMARY
   Purpose:
   Allows Agent Operations Development to view agent records and total
   transaction count without direct access to the Agents table.
   ============================================================================= */
   CREATE OR ALTER VIEW vw_AgentOps_Agents
   AS
    SELECT
        a.AgentID,
        a.FullName,
        a.CommissionRate,
        a.JoinedDate,
        COUNT(t.TransactionID) AS TotalTransactions
    FROM Agents a
    LEFT JOIN Transactions t 
        ON a.AgentID = t.AgentID
    GROUP BY
        a.AgentID,
        a.FullName,
        a.CommissionRate,
        a.JoinedDate;
GO

GRANT SELECT ON vw_AgentOps_Agents TO AgentOpsDev;
GO

/* =============================================================================
   11.2 AGENT OPERATIONS VIEW: AGENT TRANSACTIONS
   Purpose:
   Allows Agent Operations Development to view transaction records related
   to agents without directly accessing the Transactions table.
   ============================================================================= */

   CREATE OR ALTER VIEW vw_AgentOps_Transactions AS
    SELECT
        t.TransactionID,
        t.PropertyID,
        p.PropertyName,
        t.ClientID,
        t.AgentID,
        a.FullName AS AgentName,
        t.TransactionType,
        t.TransactionDate,
        t.Amount
    FROM Transactions t
    JOIN Properties p 
        ON t.PropertyID = p.PropertyID
    JOIN Agents a 
        ON t.AgentID = a.AgentID;
GO

GRANT SELECT ON vw_AgentOps_Transactions TO AgentOpsDev;
GO

/* =============================================================================
   11.3 AGENT OPERATIONS VIEW: PERFORMANCE SUMMARY
   Purpose:
   Provides summarized agent performance without exposing raw client PII.
   This supports agent monitoring while maintaining confidentiality.
   ============================================================================= */

   CREATE OR ALTER VIEW vw_AgentOps_PerformanceSummary AS
    SELECT
        a.AgentID,
        a.FullName AS AgentName,
        COUNT(t.TransactionID) AS TotalTransactions,
        ISNULL(SUM(t.Amount), 0) AS TotalTransactionAmount,
        ISNULL(AVG(t.Amount), 0) AS AverageTransactionAmount
    FROM Agents a
    LEFT JOIN Transactions t 
        ON a.AgentID = t.AgentID
    GROUP BY
        a.AgentID,
        a.FullName;
GO

GRANT SELECT ON vw_AgentOps_PerformanceSummary TO AgentOpsDev;
GO

/* =============================================================================
   11.4 AGENT OPERATIONS PROCEDURES
   Purpose:
   Agent Operations Development must use controlled stored procedures for
   decrypted contact viewing, new agent registration, transaction creation,
   and commission updates.
   ============================================================================= */
   /* -------------------------------------------------------------------------
   11.4.1 Procedure: Get Agent Contact Information
   Purpose:
   Retrieves decrypted agent contact information through a controlled
   procedure using WITH EXECUTE AS OWNER.
   ------------------------------------------------------------------------- */
   CREATE OR ALTER PROCEDURE sp_GetAgentContactInfo
    @AgentID INT = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    OPEN SYMMETRIC KEY PIIKey 
    DECRYPTION BY CERTIFICATE PIICert;

    SELECT
        AgentID,
        FullName,
        CONVERT(NVARCHAR(20), DECRYPTBYKEY(ContactNumber_Enc)) AS ContactNumber,
        CONVERT(NVARCHAR(100), DECRYPTBYKEY(Email_Enc)) AS Email
    FROM Agents
    WHERE (@AgentID IS NULL OR AgentID = @AgentID);

    CLOSE SYMMETRIC KEY PIIKey;
END;
GO


GRANT EXECUTE ON sp_GetAgentContactInfo TO AgentOpsDev;
GO

/* -------------------------------------------------------------------------
   11.4.2 Procedure: Register New Agent
   Purpose:
   Inserts a new agent and encrypts contact number and email automatically.
   ------------------------------------------------------------------------- */

   CREATE OR ALTER PROCEDURE sp_RegisterNewAgent
    @FullName NVARCHAR(100),
    @ContactNumber NVARCHAR(20),
    @Email NVARCHAR(100),
    @CommissionRate DECIMAL(5,2)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    IF @CommissionRate < 0 OR @CommissionRate > 100
    BEGIN
        RAISERROR('Commission rate must be between 0 and 100.', 16, 1);
        RETURN;
    END;

    OPEN SYMMETRIC KEY PIIKey 
    DECRYPTION BY CERTIFICATE PIICert;

    INSERT INTO Agents
    (
        FullName,
        ContactNumber,
        Email,
        CommissionRate,
        ContactNumber_Enc,
        Email_Enc
    )
    VALUES
    (
        @FullName,
        @ContactNumber,
        @Email,
        @CommissionRate,
        ENCRYPTBYKEY(KEY_GUID('PIIKey'), @ContactNumber),
        ENCRYPTBYKEY(KEY_GUID('PIIKey'), @Email)
    );

    CLOSE SYMMETRIC KEY PIIKey;
END;
GO


GRANT EXECUTE ON sp_RegisterNewAgent TO AgentOpsDev;
GO

/* -------------------------------------------------------------------------
   11.4.3 Procedure: Add Transaction
   Purpose:
   Allows Agent Operations Development to create a transaction through a
   controlled procedure instead of direct table access.
   ------------------------------------------------------------------------- */

   CREATE OR ALTER PROCEDURE sp_AddTransaction
    @PropertyID INT,
    @ClientID INT,
    @AgentID INT,
    @TransactionType NVARCHAR(50),
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Transactions
    (
        PropertyID,
        ClientID,
        AgentID,
        TransactionType,
        Amount
    )
    VALUES
    (
        @PropertyID,
        @ClientID,
        @AgentID,
        @TransactionType,
        @Amount
    );
END;
GO

GRANT EXECUTE ON sp_AddTransaction TO AgentOpsDev;
GO

/* -------------------------------------------------------------------------
   11.4.4 Procedure: Update Agent Commission
   Purpose:
   Allows Agent Operations Development to update commission rate through
   a controlled procedure instead of direct table access.
   ------------------------------------------------------------------------- */
   CREATE OR ALTER PROCEDURE sp_UpdateAgentCommission
    @AgentID INT,
    @NewCommissionRate DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @NewCommissionRate < 0 OR @NewCommissionRate > 100
    BEGIN
        RAISERROR('Commission rate must be between 0 and 100.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM Agents
        WHERE AgentID = @AgentID
    )
    BEGIN
        RAISERROR('Agent does not exist.', 16, 1);
        RETURN;
    END;

    UPDATE Agents
    SET CommissionRate = @NewCommissionRate
    WHERE AgentID = @AgentID;
END;
GO

GRANT EXECUTE ON sp_UpdateAgentCommission TO AgentOpsDev;
GO

/* =============================================================================
   11.5 AGENT OPERATIONS - PERFORMANCE SUMMARY VIEW
   Purpose:
   Provides summarized agent performance without exposing raw client PII.
   AgentOpsDev can view agent performance through this view instead of
   directly accessing the Agents or Transactions base tables.
   ============================================================================= */

CREATE OR ALTER VIEW vw_AgentOps_PerformanceSummary AS
    SELECT
        a.AgentID,
        a.FullName AS AgentName,
        COUNT(t.TransactionID) AS TotalTransactions,
        ISNULL(SUM(t.Amount), 0) AS TotalTransactionAmount,
        ISNULL(AVG(t.Amount), 0) AS AverageTransactionAmount
    FROM Agents a
    LEFT JOIN Transactions t
        ON a.AgentID = t.AgentID
    GROUP BY
        a.AgentID,
        a.FullName;
GO

GRANT SELECT ON vw_AgentOps_PerformanceSummary TO AgentOpsDev;
GO


/* =============================================================================
   11.6 AGENT OPERATIONS - UPDATE AGENT COMMISSION PROCEDURE
   Purpose:
   Allows AgentOpsDev to update an agent's commission rate through a
   controlled stored procedure instead of direct UPDATE permission on
   the Agents table.
   ============================================================================= */

CREATE OR ALTER PROCEDURE sp_UpdateAgentCommission
    @AgentID INT,
    @NewCommissionRate DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @NewCommissionRate < 0 OR @NewCommissionRate > 100
    BEGIN
        RAISERROR('Commission rate must be between 0 and 100.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM Agents
        WHERE AgentID = @AgentID
    )
    BEGIN
        RAISERROR('Agent does not exist.', 16, 1);
        RETURN;
    END;

    UPDATE Agents
    SET CommissionRate = @NewCommissionRate
    WHERE AgentID = @AgentID;
END;
GO

GRANT EXECUTE ON sp_UpdateAgentCommission TO AgentOpsDev;
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
        DEFAULT SUSER_SNAME(),

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
        SUSER_SNAME(),
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
   ============================================================================= */

USE master;
GO
CREATE CERTIFICATE TDECert WITH SUBJECT = 'Certificate for Transparent Data Encryption - GreenAcresEMS_Final';
GO

USE GreenAcresEMS_Final;
GO
CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE TDECert;
GO

ALTER DATABASE GreenAcresEMS_Final SET ENCRYPTION ON;
GO

-- Verify TDE is active
SELECT name, is_encrypted FROM sys.databases WHERE name = 'GreenAcresEMS_Final';
GO


/* =============================================================================
   SECTION 13: BACKUPS (Availability)
   Purpose: Full, Differential, and Transaction Log backups, plus backups of
   BOTH certificates used above. Losing PIICert makes column-encrypted PII
   permanently unrecoverable; losing TDECert makes the ENTIRE database
   permanently unrecoverable - even with a valid, otherwise-intact database
   backup file, because the decryption key would no longer exist anywhere.
   >>> CHANGE ME - update paths to folders that exist on your machine.
   ============================================================================= */

BACKUP DATABASE GreenAcresEMS_Final
    TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Full.bak'
    WITH INIT, NAME = 'GreenAcresEMS_Final-Full Database Backup';
GO

BACKUP DATABASE GreenAcresEMS_Final
    TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Diff.bak'
    WITH DIFFERENTIAL, NAME = 'GreenAcresEMS_Final-Differential Backup';
GO

BACKUP LOG GreenAcresEMS_Final
    TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Log.trn'
    WITH NAME = 'GreenAcresEMS_Final-Transaction Log Backup';
GO

BACKUP CERTIFICATE PIICert
    TO FILE = 'C:\GreenAcresBackups\PIICert.cer'
    WITH PRIVATE KEY (
        FILE = 'C:\GreenAcresBackups\PIICert.pvk',
        ENCRYPTION BY PASSWORD = 'PIICertBackup@2026Strong!'
    );
GO

USE master;
GO
BACKUP CERTIFICATE TDECert
    TO FILE = 'C:\GreenAcresBackups\TDECert.cer'
    WITH PRIVATE KEY (
        FILE = 'C:\GreenAcresBackups\TDECert.pvk',
        ENCRYPTION BY PASSWORD = 'TDECertBackup@2026Strong!'
    );
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

USE GreenAcresEMS_Final;
GO

CREATE DATABASE AUDIT SPECIFICATION GreenAcres_DBAuditSpec
    FOR SERVER AUDIT GreenAcres_ServerAudit
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Clients BY PUBLIC),
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Agents  BY PUBLIC),
    ADD (UPDATE ON dbo.Properties BY PUBLIC),
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),
    ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP)
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
   Section 16. This fires on every connection attempt to the SQL Server
   instance (authentication events), independent of any table activity,
   giving a lightweight running log of who connected, when, and from where -
   complementary to the Server Audit's FAILED_LOGIN_GROUP, which records
   failures; this trigger records every attempt, successful or not.
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

CREATE TRIGGER trg_LogonAudit
ON ALL SERVER
FOR LOGON
AS
BEGIN
    INSERT INTO master.dbo.LoginAudit (LoginName, ClientHost)
    VALUES (ORIGINAL_LOGIN(), HOST_NAME());
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
    ChangedBy   NVARCHAR(100) DEFAULT SUSER_SNAME(),
    ChangedDate DATETIME DEFAULT GETDATE(),
    OldValue    NVARCHAR(MAX),
    NewValue    NVARCHAR(MAX)
);
GO
GRANT SELECT ON AuditLog TO DBAdminRole;
GO

-- 16.1 Auditing trigger: Properties (UPDATE)
CREATE TRIGGER trg_Properties_AuditUpdate
ON Properties AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (TableName, Operation, RecordID, OldValue, NewValue)
    SELECT
        'Properties', 'UPDATE', i.PropertyID,
        (SELECT d.PropertyID, d.PropertyName, d.Address, d.City, d.State, d.Price, d.Status
         FROM deleted d WHERE d.PropertyID = i.PropertyID FOR JSON AUTO),
        (SELECT i2.PropertyID, i2.PropertyName, i2.Address, i2.City, i2.State, i2.Price, i2.Status
         FROM inserted i2 WHERE i2.PropertyID = i.PropertyID FOR JSON AUTO)
    FROM inserted i JOIN deleted d ON i.PropertyID = d.PropertyID;
END;
GO

-- 16.2 Auditing trigger: Clients (INSERT)
CREATE TRIGGER trg_Clients_AuditInsert
ON Clients AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (TableName, Operation, RecordID, NewValue)
    SELECT
        'Clients', 'INSERT', i.ClientID,
        (SELECT i2.ClientID, i2.FullName, i2.RegisteredDate
         FROM inserted i2 WHERE i2.ClientID = i.ClientID FOR JSON AUTO)
    FROM inserted i;
END;
GO

-- 16.3 Auditing trigger: Agents (INSERT)
CREATE TRIGGER trg_Agents_AuditInsert
ON Agents AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (TableName, Operation, RecordID, NewValue)
    SELECT
        'Agents', 'INSERT', i.AgentID,
        (SELECT i2.AgentID, i2.FullName, i2.CommissionRate, i2.JoinedDate
         FROM inserted i2 WHERE i2.AgentID = i.AgentID FOR JSON AUTO)
    FROM inserted i;
END;
GO

-- 16.4 Auditing trigger: Transactions (INSERT) - financially significant, always traceable
CREATE TRIGGER trg_Transactions_AuditInsert
ON Transactions AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (TableName, Operation, RecordID, NewValue)
    SELECT
        'Transactions', 'INSERT', i.TransactionID,
        (SELECT i2.TransactionID, i2.PropertyID, i2.ClientID, i2.AgentID, i2.TransactionType, i2.Amount
         FROM inserted i2 WHERE i2.TransactionID = i.TransactionID FOR JSON AUTO)
    FROM inserted i;
END;
GO

-- 16.5 Operational trigger: auto-update Property status on a new transaction
CREATE TRIGGER trg_Transaction_UpdatePropertyStatus
ON Transactions AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET p.Status = 'Sold', p.ModifiedDate = GETDATE(), p.ModifiedBy = SUSER_SNAME()
    FROM Properties p JOIN inserted i ON p.PropertyID = i.PropertyID
    WHERE i.TransactionType = 'Sale';

    UPDATE p
    SET p.Status = 'Rented', p.ModifiedDate = GETDATE(), p.ModifiedBy = SUSER_SNAME()
    FROM Properties p JOIN inserted i ON p.PropertyID = i.PropertyID
    WHERE i.TransactionType = 'Rent';
END;
GO

-- 16.6 Operational trigger: block maintenance requests on a Sold property
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

-- Step 1: Drop the existing policy (it depends on the function, so must go first)
DROP SECURITY POLICY TransactionAccessPolicy;
GO

-- Step 2: Now alter the function to include AgentOpsDev
ALTER FUNCTION dbo.fn_TransactionAccessPredicate(@AgentID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS AccessResult
       WHERE IS_MEMBER('DBAdminRole') = 1
          OR IS_MEMBER('AnalyticsTeam') = 1
          OR IS_MEMBER('AgentOpsDev') = 1
          OR USER_NAME() = 'dbo';
GO

-- Step 3: Recreate the policy pointing at the updated function
CREATE SECURITY POLICY TransactionAccessPolicy
    ADD FILTER PREDICATE dbo.fn_TransactionAccessPredicate(AgentID) ON dbo.Transactions
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
  AND dp.name IN ('PropertyMgmtDev','ClientPortalDev','AnalyticsTeam','DBAdminRole','AgentOpsDev')
GROUP BY dp.name
ORDER BY dp.name;
GO


/* =============================================================================
   SECTION 19: VERIFICATION - FULL PER-DEPARTMENT ACCESS TEST
   Purpose: Prove every role can use its Views/Procedures but is denied
   direct table access. Run each block separately in your own SSMS session
   and observe the results (marked WORKS / DENIED for what to expect).
   ============================================================================= */

-- 19.1 Client Portal Development (Sehneel Ansari)
REVERT;
EXECUTE AS USER = 'sehneel_ansari_login';
SELECT * FROM vw_ClientPortal_Clients;                          -- WORKS
EXEC sp_GetClientContactInfo;                                   -- WORKS: decrypted PII
EXEC sp_RegisterNewClient @FullName='Verification Client', @ContactNumber='019-0000001', @Email='verify1@gmail.com', @Address='1 Jalan Verify, Shah Alam';  -- WORKS
SELECT * FROM Clients;                                          -- DENIED
REVERT;

-- 19.2 Property Management Development (Izzah Zulkafli)
EXECUTE AS USER = 'izzah_zulkafli_login';
SELECT * FROM vw_PropertyMgmt_Properties;                       -- WORKS
SELECT * FROM vw_PropertyMgmt_MaintenanceRequests;               -- WORKS
EXEC sp_UpdatePropertyStatus @PropertyID=3, @NewStatus='Rented'; -- WORKS
SELECT * FROM Properties;                                       -- DENIED
REVERT;

-- 19.3 Analytics (Priya Suhuba)
EXECUTE AS USER = 'priya_suhuba_login';
SELECT * FROM vw_Analytics_ClientSummary;                        -- WORKS: masked PII visible
SELECT * FROM vw_Analytics_AgentPerformance;                     -- WORKS: masked email, real aggregates
SELECT * FROM Clients;                                           -- DENIED
REVERT;

-- 19.4 Database Administration (Imran Amir)
EXECUTE AS USER = 'imran_amir_login';
SELECT ClientID, FullName, ContactNumber, Email, Address FROM Clients;  -- WORKS: real unmasked PII
SELECT * FROM Users;                                             -- WORKS: full access, but PasswordHash still unreadable
REVERT;

-- 19.5 Agent Operations Development (Lim Jia Hui)
USE GreenAcresEMS_Final;
GO
EXECUTE AS USER = 'limjiahui_login';
SELECT * FROM vw_AgentOps_Agents; 
-- WORKS
SELECT* FROM vw_AgentOps_Transactions;
--WORKS
SELECT*FROM vw_AgentOps_PerformanceSummary;
--WORKS
EXEC sp_GetAgentContactInfo; 
-- WORKS: decrypted PII
EXEC sp_RegisterNewAgent
    @FullName = 'Verification Agent',
    @ContactNumber = '019-2223333',
    @Email = 'verify.agent@greenacres.com',
    @CommissionRate = 3.20;
EXEC sp_UpdateAgentCommission
    @AgentID = 1,
    @NewCommissionRate = 3.80;
SELECT * FROM AgentCommissionHistory;

SELECT * FROM Agents;   
-- DENIED
SELECT * FROM Clients;
--DENIED
REVERT;
GO


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
WHERE t.name IN ('Properties','Clients','Agents','Transactions','MaintenanceRequests','Departments','Users','AuditLog')
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
/* =============================================================================
   SECTION 21: FINAL BACKUP
   Purpose: Take one last backup reflecting the fully completed database,
   after every section including TDE, Triggers, and Auditing has been
   applied.
   ============================================================================= */

BACKUP DATABASE GreenAcresEMS_Final
    TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Final_Full.bak'
    WITH INIT, NAME = 'GreenAcresEMS_Final-Final Submission Backup';
GO
