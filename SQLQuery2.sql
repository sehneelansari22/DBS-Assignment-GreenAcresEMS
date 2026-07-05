-- =========================================================================
-- STEP 0: CREATE THE DATABASE
-- Run this first before anything else
-- =========================================================================
CREATE DATABASE GreenAcresEMS;
GO

USE GreenAcresEMS;
GO

-- =========================================================================
-- SECTION 1: CREATE TABLES
-- ... (rest of your full script, Section 1 through Section 17)


-- =========================================================================
-- SECTION 1: CREATE TABLES
-- Purpose: Rebuild the base EMS schema as originally provided by the
-- previous developers (Appendix I), before any security enhancements
-- are applied. This represents the "before" state of the database.
-- =========================================================================

-- Table: Properties - stores all property listings managed by the company
CREATE TABLE Properties (
    PropertyID INT IDENTITY(1,1) PRIMARY KEY,
    PropertyName NVARCHAR(150),
    Address NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(100),
    Price DECIMAL(18,2),
    Status NVARCHAR(50), -- like 'Available', 'Sold', 'Rented'
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Table: Clients - stores personal details of clients buying/renting properties
CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100),
    ContactNumber NVARCHAR(20),
    Email NVARCHAR(100),
    Address NVARCHAR(255),
    RegisteredDate DATETIME DEFAULT GETDATE()
);

-- Table: Agents - stores details of real estate agents and their commission rates
CREATE TABLE Agents (
    AgentID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100),
    ContactNumber NVARCHAR(20),
    Email NVARCHAR(100),
    CommissionRate DECIMAL(5,2),
    JoinedDate DATETIME DEFAULT GETDATE()
);

-- Table: Transactions - records every sale/rental transaction, linking Properties, Clients, and Agents
CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    PropertyID INT FOREIGN KEY REFERENCES Properties(PropertyID),
    ClientID INT FOREIGN KEY REFERENCES Clients(ClientID),
    AgentID INT FOREIGN KEY REFERENCES Agents(AgentID),
    TransactionType NVARCHAR(50), -- like 'Sale', 'Rent'
    TransactionDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(18,2)
);

-- Table: MaintenanceRequests - tracks maintenance/repair requests linked to a property
CREATE TABLE MaintenanceRequests (
    RequestID INT IDENTITY(1,1) PRIMARY KEY,
    PropertyID INT FOREIGN KEY REFERENCES Properties(PropertyID),
    RequestDetails NVARCHAR(MAX),
    RequestDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(50) -- like 'Pending', 'In Progress', 'Completed'
);


-- =========================================================================
-- SECTION 2: INSERT SAMPLE DATA
-- Purpose: Populate all tables with sufficient realistic data so that
-- security features (masking, encryption, auditing) can be properly
-- demonstrated and tested later in the assignment.
-- =========================================================================

-- Sample property listings across various locations, prices, and statuses
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

-- Sample clients with realistic names, contact numbers, emails, and addresses
-- Note: FullName, ContactNumber, Email, Address are treated as PII and will
-- be encrypted/masked later in the Data Protection section
INSERT INTO Clients (FullName, ContactNumber, Email, Address) VALUES
('Sehneel Ansari', '012-3635689', 'sehneel.ansari@gmail.com', '15 Jalan SS2/24, SS2, 47300 Petaling Jaya, Selangor'),
('Lim Chee Yee', '013-0227763', 'limcheeyee@yahoo.com', '7 Jalan Kenanga 5, Bandar Puchong Jaya, 47100 Puchong, Selangor'),
('Izzah Zulkafli', '019-4316695', 'izzah.zulkafli@gmail.com', '23 Jalan Anggerik, Taman Melawati, 53100 Kuala Lumpur'),
('Imran Amir', '016-6767676', 'imran.amir88@hotmail.com', '4 Jalan Bunga Raya 3, Taman Sri Rawang, 48000 Rawang, Selangor'),
('Lim Jia Hui', '017-7234523', 'jiahui.lim@gmail.com', '19 Jalan Pinang, Taman Desa, 58100 Kuala Lumpur'),
('Tsang Da Xin', '018-0293833', 'daxin.tsang@yahoo.com', '2 Jalan Sutera 12, Taman Sentosa, 41200 Klang, Selangor'),
('Dewi Rajan Priya', '019-929945', 'dewi.rajanpriya@gmail.com', '31 Jalan Cempaka 8, Bandar Baru Bangi, 43650 Bangi, Selangor'),
('Summitha Kumarin Ravichander', '011-3334456', 'summitha.kr@outlook.com', '6 Jalan Kajang Impian, Taman Kajang Impian, 43000 Kajang, Selangor'),
('James Chan Hong Yu', '012-1909834', 'jameschan.hy@gmail.com', '11 Jalan Ampang Utama 2/1, Taman Dato Ahmad Razali, 68000 Ampang, Selangor'),
('Low Yan Cheng', '013-2123345', 'yancheng.low@yahoo.com', '9 Jalan Cheras Baru, Taman Cheras Baru, 56100 Cheras, Kuala Lumpur');

-- Sample agents with contact details and commission rates
-- Note: CommissionRate is treated as sensitive business data (Internal classification)
INSERT INTO Agents (FullName, ContactNumber, Email, CommissionRate) VALUES
('Nur Alia Zahid', '019-1112222', 'aisyah.r@greenacres.com', 2.50),
('Ethan Wong', '017-2223333', 'david.lim@greenacres.com', 3.00),
('Siti Kavitha Nair', '018-3334444', 'kavitha.s@greenacres.com', 2.75),
('Ahmad Zulkarnain', '016-4445555', 'zul.k@greenacres.com', 3.25),
('Lina Grace Ho', '012-5556666', 'grace.tan@greenacres.com', 2.90);

-- Sample transactions linking properties, clients, and agents together
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

-- Sample maintenance requests linked to various properties
INSERT INTO MaintenanceRequests (PropertyID, RequestDetails, Status) VALUES
(2, 'Water seepage from ceiling causing damp patches in master bedroom', 'Completed'),
(4, 'Air conditioner not cooling properly, suspected refrigerant issue', 'In Progress'),
(7, 'Broken window glass in living room requiring replacement', 'Pending'),
(9, 'Leaking pipe detected under kitchen sink cabinet', 'Completed'),
(1, 'Electrical power trip occurs when using study room socket', 'Pending'),
(5, 'Automatic gate system unresponsive to remote control', 'In Progress'),
(6, 'Water heater producing unusual loud sounds, replacement needed', 'Completed'),
(8, 'Mold buildup spreading on bathroom ceiling surface', 'Pending');



-- =========================================================================
-- SECTION 3: DEPARTMENTS AND USERS TABLE (APPLICATION-LEVEL, FOR HASHING)
-- Purpose: Add new tables (as required by the assignment) to represent the
-- new IT division structure, and demonstrate password hashing so that no
-- plain-text credentials are ever stored in the database.
-- =========================================================================


-- Departments table: represents the new IT division's specialized teams as described in the case study
CREATE TABLE Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100)
);

-- Insert the departments mentioned in the assignment 
INSERT INTO Departments (DepartmentName) VALUES
('Property Management Development'),
('Client Portal Development'),
('Analytics'),
('Database Administration');

-- Users table: represents application-level accounts for each department
-- Passwords are NEVER stored as plain text - only the one-way hashed value is stored
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) UNIQUE NOT NULL,
    PasswordSalt UNIQUEIDENTIFIER DEFAULT NEWID(),   -- random salt to prevent identical passwords producing identical hashes
    PasswordHash VARBINARY(64) NOT NULL,             -- stores the one-way hashed password only
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID),
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert one user per team member, each representing a different department
-- HASHBYTES with SHA2_256 generates a one-way hash; NEWID() adds randomness so each hash is unique
INSERT INTO Users (Username, PasswordHash, DepartmentID)
VALUES ('leon.kennedy', HASHBYTES('SHA2_256', 'Leon@2026!' + CONVERT(NVARCHAR(36), NEWID())), 1);  -- Property Management Dev

INSERT INTO Users (Username, PasswordHash, DepartmentID)
VALUES ('woo.dohwan', HASHBYTES('SHA2_256', 'DoHwan@2026!' + CONVERT(NVARCHAR(36), NEWID())), 2);  -- Client Portal Dev

INSERT INTO Users (Username, PasswordHash, DepartmentID)
VALUES ('jay.chou', HASHBYTES('SHA2_256', 'JayChou@2026!' + CONVERT(NVARCHAR(36), NEWID())), 3);   -- Analytics

INSERT INTO Users (Username, PasswordHash, DepartmentID)
VALUES ('pravin.kumar', HASHBYTES('SHA2_256', 'Pravin@2026!' + CONVERT(NVARCHAR(36), NEWID())), 4); -- Database Administration

INSERT INTO Users (Username, PasswordHash, DepartmentID)
VALUES ('ada.wong', HASHBYTES('SHA2_256', 'AdaWong@2026!' + CONVERT(NVARCHAR(36), NEWID())), 5);   -- Agent Operations Dev

-- Verify: PasswordHash column should display as unreadable binary, proving passwords are never stored in plain text
SELECT * FROM Users;


-- =========================================================================
-- SECTION 4: DATABASE ROLES AND SQL SERVER LOGINS
-- Purpose: Create actual SQL Server-level roles and logins that will control
-- REAL database permissions (separate from the Users table in Section 3,
-- which is only the application-level record of who belongs to which
-- department). Each team member gets their own login mapped to their
-- department's role.
-- =========================================================================

-- Create one database role per department - permissions will later be granted to these roles, not individual users
CREATE ROLE PropertyMgmtDev;
CREATE ROLE ClientPortalDev;
CREATE ROLE AnalyticsTeam;
CREATE ROLE DBAdminRole;
CREATE ROLE AgentOpsDev;   -- new role for the 5th department (Agent Operations Development)

-- Leon Kennedy - Property Management Development
CREATE LOGIN leon_kennedy_login WITH PASSWORD = 'Leon@2026Strong!';    -- server-level login (authentication)
CREATE USER leon_kennedy_login FOR LOGIN leon_kennedy_login;           -- database-level user (authorization) mapped to the login
ALTER ROLE PropertyMgmtDev ADD MEMBER leon_kennedy_login;              -- assign user to their department role

-- Woo Do Hwan - Client Portal Development
CREATE LOGIN woo_dohwan_login WITH PASSWORD = 'DoHwan@2026Strong!';
CREATE USER woo_dohwan_login FOR LOGIN woo_dohwan_login;
ALTER ROLE ClientPortalDev ADD MEMBER woo_dohwan_login;

-- Jay Chou - Analytics
CREATE LOGIN jay_chou_login WITH PASSWORD = 'JayChou@2026Strong!';
CREATE USER jay_chou_login FOR LOGIN jay_chou_login;
ALTER ROLE AnalyticsTeam ADD MEMBER jay_chou_login;

-- Pravin Kumar - Database Administration
CREATE LOGIN pravin_kumar_login WITH PASSWORD = 'Pravin@2026Strong!';
CREATE USER pravin_kumar_login FOR LOGIN pravin_kumar_login;
ALTER ROLE DBAdminRole ADD MEMBER pravin_kumar_login;

-- Ada Wong - Agent Operations Development
CREATE LOGIN ada_wong_login WITH PASSWORD = 'AdaWong@2026Strong!';
CREATE USER ada_wong_login FOR LOGIN ada_wong_login;
ALTER ROLE AgentOpsDev ADD MEMBER ada_wong_login;


-- =========================================================================
-- SECTION 5: DATA PROTECTION - ENCRYPTION
-- Purpose: Protect Personally Identifiable Information (PII) for Clients
-- and Agents using symmetric key encryption. Unlike hashing (Section 3),
-- encryption is two-way/reversible - this is needed because the business
-- has a legitimate need to read back a client's real phone number, email,
-- or address (e.g. to contact them), not just verify it matches.
-- =========================================================================

-- Step 5.1: Create a Master Key - this is the top-level key that protects
-- everything else below it (certificates, symmetric keys). Only needs to
-- be created ONCE per database.
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'GreenAcres@MasterKey2026!';

-- Allows the Master Key to auto-open for ANY valid session (not just yours),
-- which is required for DECRYPTBYKEYAUTOCERT to work inside views
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;
GO

-- Step 5.2: Create a Certificate - acts as a protective wrapper around
-- our symmetric key. The certificate itself is protected by the Master Key above.
CREATE CERTIFICATE PIICert
WITH SUBJECT = 'Certificate for Encrypting Client and Agent PII';

-- Step 5.3: Create a Symmetric Key - this is the actual key used to
-- encrypt/decrypt the data. AES_256 is a strong, industry-standard algorithm.
CREATE SYMMETRIC KEY PIIKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE PIICert;


-- =========================================================================
-- Step 5.4: Add new encrypted columns to Clients table
-- We add NEW columns instead of overwriting the originals first, so we can
-- verify encryption/decryption works correctly before removing plain-text data.
-- =========================================================================
ALTER TABLE Clients ADD
    ContactNumber_Enc VARBINARY(256),
    Email_Enc VARBINARY(256),
    Address_Enc VARBINARY(256);
GO

-- Open the symmetric key so it's available for use in this session
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

-- Encrypt existing plain-text values into the new encrypted columns
UPDATE Clients
SET ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), ContactNumber),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), Email),
    Address_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), Address);

CLOSE SYMMETRIC KEY PIIKey;
GO

-- Verify: encrypted columns should show unreadable binary data (ciphertext)
SELECT ClientID, FullName, ContactNumber_Enc, Email_Enc, Address_Enc FROM Clients;
GO

-- =========================================================================
-- Step 5.4b: FIX - Backfill missing Address_Enc values
-- Purpose: The original Step 5.4 encryption update did not fully populate
-- Address_Enc for all rows (later discovered during Section 10 testing).
-- This backfills any missing encrypted addresses for existing clients.
-- =========================================================================
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

UPDATE Clients
SET Address_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), Address)
WHERE Address_Enc IS NULL AND Address IS NOT NULL;

CLOSE SYMMETRIC KEY PIIKey;
GO

-- Verify: Address_Enc should now show binary data for ClientID 1-10
SELECT ClientID, FullName, Address_Enc FROM Clients;
GO


-- =========================================================================
-- Step 5.5: Add same encrypted columns to Agents table (ContactNumber, Email)
-- =========================================================================
ALTER TABLE Agents ADD
    ContactNumber_Enc VARBINARY(256),
    Email_Enc VARBINARY(256);
GO

OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

UPDATE Agents
SET ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), ContactNumber),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), Email);

CLOSE SYMMETRIC KEY PIIKey;
GO

-- Verify: encrypted columns should show unreadable binary data (ciphertext)
SELECT AgentID, FullName, ContactNumber_Enc, Email_Enc FROM Agents;
GO

-- =========================================================================
-- Step 5.5b - Backfill missing Agents encrypted columns
-- Purpose: Same issue as Step 5.4b (Clients) - the original Step 5.5
-- encryption update did not fully populate ContactNumber_Enc/Email_Enc
-- for all agent rows (discovered during Section 11 testing). This
-- backfills any missing encrypted values.
-- =========================================================================
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

UPDATE Agents
SET ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), ContactNumber),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), Email)
WHERE ContactNumber_Enc IS NULL OR Email_Enc IS NULL;

CLOSE SYMMETRIC KEY PIIKey;
GO

-- Verify: should now show binary data for all agents
SELECT AgentID, FullName, ContactNumber_Enc, Email_Enc FROM Agents;
GO


-- =========================================================================
-- Step 5.6: Demonstrate DECRYPTION - proving authorized users (e.g. DBA)
-- can still recover the original readable value when legitimately needed
-- =========================================================================
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

SELECT
    ClientID,
    FullName,
    CONVERT(NVARCHAR(20), DECRYPTBYKEY(ContactNumber_Enc)) AS DecryptedContactNumber,
    CONVERT(NVARCHAR(100), DECRYPTBYKEY(Email_Enc)) AS DecryptedEmail,
    CONVERT(NVARCHAR(255), DECRYPTBYKEY(Address_Enc)) AS DecryptedAddress
FROM Clients;

CLOSE SYMMETRIC KEY PIIKey;
GO

-- =========================================================================
-- SECTION 6: DATA PROTECTION - DYNAMIC DATA MASKING
-- Purpose: Allow certain roles (e.g. Analytics) to see that PII data EXISTS
-- and query around it, without exposing the real readable value. Unlike
-- encryption (which protects data at rest), masking is a DISPLAY-LEVEL
-- control - the real data is still there underneath, just hidden from
-- roles that don't have UNMASK permission.
-- =========================================================================

-- Mask Clients.Email using the built-in email masking function
-- like 'sehneel.ansari@gmail.com' displays as 'sXXX@XXXX.com'
ALTER TABLE Clients
ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');

-- Mask Clients.ContactNumber using partial masking
-- Shows first 3 characters, hides the rest, reveals last 2 characters
ALTER TABLE Clients
ALTER COLUMN ContactNumber ADD MASKED WITH (FUNCTION = 'partial(3,"XXXXXXX",2)');

-- Mask Clients.Address completely using the default masking function
-- Default masking fully hides the value (shows 'XXXX' regardless of type)
ALTER TABLE Clients
ALTER COLUMN Address ADD MASKED WITH (FUNCTION = 'default()');
GO

-- Apply the same masking to Agents' PII columns
ALTER TABLE Agents
ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');

ALTER TABLE Agents
ALTER COLUMN ContactNumber ADD MASKED WITH (FUNCTION = 'partial(3,"XXXXXXX",2)');
GO


-- =========================================================================
-- Step 6.1: Grant UNMASK permission ONLY to DBAdminRole
-- Any role WITHOUT this permission will see masked (fake) values,
-- even though the real data is technically still in the column.
-- =========================================================================
GRANT UNMASK TO DBAdminRole;
GO


-- =========================================================================
-- Step 6.2: Test masking - compare what different roles see
-- =========================================================================

-- masking does not apply to db_owner/sysadmin by default
SELECT ClientID, FullName, ContactNumber, Email, Address FROM Clients;

-- To truly test masking, run this as a role WITHOUT UNMASK permission, e.g.:
EXECUTE AS USER = 'jay_chou_login';  -- Analytics - should see masked data
SELECT ClientID, FullName, ContactNumber, Email, Address FROM Clients;
REVERT;  -- switch back to your own session
-- TEMPORARY: grant SELECT so we can test masking works correctly
-- This will be replaced later by proper Views once we build the access layer
GRANT SELECT ON Clients TO AnalyticsTeam;
GO

EXECUTE AS USER = 'jay_chou_login';
SELECT ClientID, FullName, ContactNumber, Email, Address FROM Clients;
REVERT;

-- =========================================================================
-- SECTION 7: VIEWS AND STORED PROCEDURES - CLIENT PORTAL DEVELOPMENT
-- Purpose: Build the access-control layer for Client Portal Development.
-- Basic client info is exposed via a View; sensitive PII (decrypted) is
-- only accessible through a Stored Procedure using WITH EXECUTE AS OWNER,
-- which lets the procedure use the encryption key regardless of the
-- caller's own permissions. Writes also go through a Stored Procedure so
-- encryption is handled automatically and consistently. Direct table
-- access is denied entirely, forcing all access through these controlled
-- objects only (Principle of Least Privilege).
-- =========================================================================

-- -------------------------------------------------------------------------
-- 7.1: View - basic (non-sensitive) client info
-- -------------------------------------------------------------------------
CREATE VIEW vw_ClientPortal_Clients AS
SELECT
    ClientID,
    FullName,
    RegisteredDate
FROM Clients;
GO

GRANT SELECT ON vw_ClientPortal_Clients TO ClientPortalDev;
GO


-- -------------------------------------------------------------------------
-- 7.2: Stored Procedure - controlled decrypted READ of sensitive PII
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_GetClientContactInfo
    @ClientID INT = NULL   -- pass a specific ClientID, or leave NULL for all clients
WITH EXECUTE AS OWNER
AS
BEGIN
    OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

    SELECT
        ClientID,
        FullName,
        CONVERT(NVARCHAR(20), DECRYPTBYKEY(ContactNumber_Enc)) AS ContactNumber,
        CONVERT(NVARCHAR(100), DECRYPTBYKEY(Email_Enc)) AS Email,
        CONVERT(NVARCHAR(255), DECRYPTBYKEY(Address_Enc)) AS Address
    FROM Clients
    WHERE (@ClientID IS NULL OR ClientID = @ClientID);

    CLOSE SYMMETRIC KEY PIIKey;
END;
GO

GRANT EXECUTE ON sp_GetClientContactInfo TO ClientPortalDev;
GO


-- -------------------------------------------------------------------------
-- 7.3: Stored Procedure - controlled encrypted WRITE (new client registration)
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_RegisterNewClient
    @FullName NVARCHAR(100),
    @ContactNumber NVARCHAR(20),
    @Email NVARCHAR(100),
    @Address NVARCHAR(255)
WITH EXECUTE AS OWNER
AS
BEGIN
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


-- -------------------------------------------------------------------------
-- 7.4: Deny direct table access - forces all access through views/procedures
-- -------------------------------------------------------------------------
DENY SELECT, INSERT, UPDATE, DELETE ON Clients TO ClientPortalDev;
GO


-- -------------------------------------------------------------------------
-- 7.5: Test - confirm the full access pattern works as intended
-- -------------------------------------------------------------------------
REVERT;
EXECUTE AS USER = 'woo_dohwan_login';

SELECT * FROM vw_ClientPortal_Clients;      -- WORKS: basic info via view
EXEC sp_GetClientContactInfo;               -- WORKS: decrypted PII via procedure
EXEC sp_RegisterNewClient                   -- WORKS: encrypted write via procedure
    @FullName = 'Test Client 2',
    @ContactNumber = '019-1111111',
    @Email = 'test2@gmail.com',
    @Address = '20 Jalan Test 2, Shah Alam, Selangor';
SELECT * FROM Clients;                      -- DENIED: direct table access blocked

REVERT;

-- =========================================================================
-- SCHEMA IMPROVEMENT: Add change-tracking columns to Properties
-- Purpose: Supports Integrity by recording who last modified a property
-- record and when. Required before Section 8, since the Property
-- Management view/procedures reference these columns.
-- =========================================================================
ALTER TABLE Properties ADD
    ModifiedDate DATETIME NULL,
    ModifiedBy NVARCHAR(100) NULL;
GO

-- =========================================================================
-- SECTION 8: VIEWS AND STORED PROCEDURES - PROPERTY MANAGEMENT DEVELOPMENT
-- Purpose: Build the access-control layer for Property Management Dev.
-- No PII is involved here (Properties/MaintenanceRequests contain business
-- data, not personal data), so this section is simpler - focused on
-- controlled reads (View) and controlled writes (Stored Procedures),
-- with direct table access denied to enforce least privilege.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 8.1: View - property listings with related maintenance request counts
-- Gives Property Management Dev a useful combined view for their work,
-- rather than raw table access.
-- -------------------------------------------------------------------------
CREATE VIEW vw_PropertyMgmt_Properties AS
SELECT
    p.PropertyID,
    p.PropertyName,
    p.Address,
    p.City,
    p.State,
    p.Price,
    p.Status,
    p.CreatedDate,
    p.ModifiedDate,
    p.ModifiedBy,
    (SELECT COUNT(*) FROM MaintenanceRequests mr WHERE mr.PropertyID = p.PropertyID AND mr.Status <> 'Completed') AS OpenMaintenanceRequests
FROM Properties p;
GO

GRANT SELECT ON vw_PropertyMgmt_Properties TO PropertyMgmtDev;
GO


-- -------------------------------------------------------------------------
-- 8.2: Stored Procedure - update a property's status (controlled write)
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_UpdatePropertyStatus
    @PropertyID INT,
    @NewStatus NVARCHAR(50)
AS
BEGIN
    UPDATE Properties
    SET Status = @NewStatus,
        ModifiedDate = GETDATE(),
        ModifiedBy = SUSER_SNAME()
    WHERE PropertyID = @PropertyID;
END;
GO

GRANT EXECUTE ON sp_UpdatePropertyStatus TO PropertyMgmtDev;
GO


-- -------------------------------------------------------------------------
-- 8.3: Stored Procedure - add a new property listing (controlled write)
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_AddNewProperty
    @PropertyName NVARCHAR(150),
    @Address NVARCHAR(255),
    @City NVARCHAR(100),
    @State NVARCHAR(100),
    @Price DECIMAL(18,2),
    @Status NVARCHAR(50)
AS
BEGIN
    INSERT INTO Properties (PropertyName, Address, City, State, Price, Status)
    VALUES (@PropertyName, @Address, @City, @State, @Price, @Status);
END;
GO

GRANT EXECUTE ON sp_AddNewProperty TO PropertyMgmtDev;
GO


-- -------------------------------------------------------------------------
-- 8.4: Stored Procedure - log a new maintenance request (controlled write)
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_AddMaintenanceRequest
    @PropertyID INT,
    @RequestDetails NVARCHAR(MAX)
AS
BEGIN
    INSERT INTO MaintenanceRequests (PropertyID, RequestDetails, Status)
    VALUES (@PropertyID, @RequestDetails, 'Pending');
END;
GO

GRANT EXECUTE ON sp_AddMaintenanceRequest TO PropertyMgmtDev;
GO


-- -------------------------------------------------------------------------
-- 8.5: Stored Procedure - update maintenance request status (controlled write)
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_UpdateMaintenanceStatus
    @RequestID INT,
    @NewStatus NVARCHAR(50)
AS
BEGIN
    UPDATE MaintenanceRequests
    SET Status = @NewStatus
    WHERE RequestID = @RequestID;
END;
GO

GRANT EXECUTE ON sp_UpdateMaintenanceStatus TO PropertyMgmtDev;
GO


-- -------------------------------------------------------------------------
-- 8.6: View - maintenance requests (read access)
-- -------------------------------------------------------------------------
CREATE VIEW vw_PropertyMgmt_MaintenanceRequests AS
SELECT
    mr.RequestID,
    mr.PropertyID,
    p.PropertyName,
    mr.RequestDetails,
    mr.RequestDate,
    mr.Status
FROM MaintenanceRequests mr
JOIN Properties p ON mr.PropertyID = p.PropertyID;
GO

GRANT SELECT ON vw_PropertyMgmt_MaintenanceRequests TO PropertyMgmtDev;
GO


-- -------------------------------------------------------------------------
-- 8.7: Deny direct table access - forces all access through views/procedures
-- -------------------------------------------------------------------------
DENY SELECT, INSERT, UPDATE, DELETE ON Properties TO PropertyMgmtDev;
DENY SELECT, INSERT, UPDATE, DELETE ON MaintenanceRequests TO PropertyMgmtDev;
GO


-- -------------------------------------------------------------------------
-- 8.8: Test - confirm the full access pattern works as intended
-- -------------------------------------------------------------------------
REVERT;
EXECUTE AS USER = 'leon_kennedy_login';

SELECT * FROM vw_PropertyMgmt_Properties;              -- WORKS: view access
SELECT * FROM vw_PropertyMgmt_MaintenanceRequests;     -- WORKS: view access

EXEC sp_UpdatePropertyStatus @PropertyID = 3, @NewStatus = 'Rented';   -- WORKS
EXEC sp_AddMaintenanceRequest @PropertyID = 5, @RequestDetails = 'Test request - garden fence damaged';  -- WORKS

SELECT * FROM Properties;               -- DENIED: direct table access blocked
SELECT * FROM MaintenanceRequests;      -- DENIED: direct table access blocked

REVERT;

-- =========================================================================
-- SECTION 9: VIEWS - ANALYTICS TEAM (READ-ONLY, MASKED)
-- Purpose: Analytics needs to see patterns and aggregates across Clients,
-- Agents, Properties, and Transactions - but should never see raw PII
-- or need write access. Views here rely on the Dynamic Data Masking
-- already applied in Section 6 (Analytics has NO UNMASK permission, so
-- masked columns automatically display as masked when queried through
-- these views). No stored procedures needed - this role is read-only.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 9.1: View - client summary (masked PII, safe for analytics use)
-- Masking is automatic here since AnalyticsTeam has no UNMASK permission -
-- the same SELECT that shows real data to a DBA will show masked data here.
-- -------------------------------------------------------------------------
CREATE VIEW vw_Analytics_ClientSummary AS
SELECT
    ClientID,
    FullName,
    ContactNumber,   -- will display masked (e.g. 012XXXXXXX89) for AnalyticsTeam
    Email,           -- will display masked (e.g. sXXX@XXXX.com) for AnalyticsTeam
    RegisteredDate
FROM Clients;
GO

GRANT SELECT ON vw_Analytics_ClientSummary TO AnalyticsTeam;
GO


-- -------------------------------------------------------------------------
-- 9.2: View - agent performance summary
-- CommissionRate is Internal classification (sensitive business data) -
-- excluded entirely here rather than masked, since averaging masked
-- numeric data would be meaningless for analytics anyway.
-- -------------------------------------------------------------------------
CREATE VIEW vw_Analytics_AgentPerformance AS
SELECT
    a.AgentID,
    a.FullName,
    a.Email,          -- masked automatically for AnalyticsTeam
    COUNT(t.TransactionID) AS TotalTransactions,
    SUM(t.Amount) AS TotalSalesValue
FROM Agents a
LEFT JOIN Transactions t ON a.AgentID = t.AgentID
GROUP BY a.AgentID, a.FullName, a.Email;
GO

GRANT SELECT ON vw_Analytics_AgentPerformance TO AnalyticsTeam;
GO


-- -------------------------------------------------------------------------
-- 9.3: View - property market analysis (no PII involved at all)
-- -------------------------------------------------------------------------
CREATE VIEW vw_Analytics_PropertyMarket AS
SELECT
    City,
    State,
    Status,
    COUNT(*) AS PropertyCount,
    AVG(Price) AS AveragePrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Properties
GROUP BY City, State, Status;
GO

GRANT SELECT ON vw_Analytics_PropertyMarket TO AnalyticsTeam;
GO


-- -------------------------------------------------------------------------
-- 9.4: View - monthly transaction trends (business insight, no PII)
-- -------------------------------------------------------------------------
CREATE VIEW vw_Analytics_MonthlyTransactions AS
SELECT
    YEAR(TransactionDate) AS TransactionYear,
    MONTH(TransactionDate) AS TransactionMonth,
    TransactionType,
    COUNT(*) AS TransactionCount,
    SUM(Amount) AS TotalAmount
FROM Transactions
GROUP BY YEAR(TransactionDate), MONTH(TransactionDate), TransactionType;
GO

GRANT SELECT ON vw_Analytics_MonthlyTransactions TO AnalyticsTeam;
GO


-- -------------------------------------------------------------------------
-- 9.5: Clean up the TEMPORARY grant from Section 6 masking test, and
-- properly deny direct table access now that views exist
-- -------------------------------------------------------------------------
REVOKE SELECT ON Clients FROM AnalyticsTeam;   -- remove the temporary test grant

DENY SELECT, INSERT, UPDATE, DELETE ON Clients TO AnalyticsTeam;
DENY SELECT, INSERT, UPDATE, DELETE ON Agents TO AnalyticsTeam;
DENY SELECT, INSERT, UPDATE, DELETE ON Properties TO AnalyticsTeam;
DENY SELECT, INSERT, UPDATE, DELETE ON Transactions TO AnalyticsTeam;
GO


-- -------------------------------------------------------------------------
-- 9.6: Test - confirm Analytics sees masked data via views, denied on tables
-- -------------------------------------------------------------------------
REVERT;
EXECUTE AS USER = 'jay_chou_login';

SELECT * FROM vw_Analytics_ClientSummary;        -- WORKS: masked PII visible
SELECT * FROM vw_Analytics_AgentPerformance;     -- WORKS: masked email, real aggregates
SELECT * FROM vw_Analytics_PropertyMarket;       -- WORKS: no PII involved
SELECT * FROM vw_Analytics_MonthlyTransactions;  -- WORKS: no PII involved

SELECT * FROM Clients;      -- DENIED: direct table access blocked
SELECT * FROM Agents;       -- DENIED
SELECT * FROM Properties;   -- DENIED
SELECT * FROM Transactions; -- DENIED

REVERT;

-- =========================================================================
-- SECTION 10: DATABASE ADMINISTRATION ROLE
-- Purpose: Unlike developer roles (which access data only through views/
-- procedures), DBAdminRole is granted broad direct access to all tables.
-- This is justified because DBAs are responsible for whole-system tasks -
-- maintenance, troubleshooting, backups, and auditing - that require
-- visibility across the entire database, not just one feature area.
-- UNMASK was already granted in Section 6, so DBAs also see real PII
-- values, not masked ones. This broad access is balanced by full
-- accountability - every DBA action is captured by the auditing and
-- trigger mechanisms built in later sections, so no one is exempt from
-- oversight even with elevated privileges.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 10.1: Grant full direct access to all core tables
-- -------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON Properties TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Clients TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Agents TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Transactions TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON MaintenanceRequests TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Departments TO DBAdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Users TO DBAdminRole;
GO

-- -------------------------------------------------------------------------
-- 10.2: Grant access to view/query the AuditLog table (read-only - DBAs
-- should be able to review audit history, but not alter it, to preserve
-- audit trail integrity)
-- -------------------------------------------------------------------------
GRANT SELECT ON AuditLog TO DBAdminRole;
GO
-- Note: run this once the AuditLog table exists (created in Section 5 of
-- your original guide / will be created in the upcoming Auditing section
-- if not already done)

-- -------------------------------------------------------------------------
-- 10.3: Grant access to the encryption certificate and symmetric key, so
-- DBAs can decrypt PII directly when troubleshooting (separate from the
-- controlled procedures developers use)
-- -------------------------------------------------------------------------
GRANT CONTROL ON CERTIFICATE::PIICert TO DBAdminRole;
GO

GRANT VIEW DEFINITION ON SYMMETRIC KEY::PIIKey TO DBAdminRole;
GO

-- -------------------------------------------------------------------------
-- 10.4: Confirm UNMASK is already granted (from Section 6) - re-run
-- safely, GRANT is idempotent if already applied
-- -------------------------------------------------------------------------
GRANT UNMASK TO DBAdminRole;
GO


-- -------------------------------------------------------------------------
-- 10.5: Test - confirm Pravin (DBA) sees everything, unmasked, real values
-- -------------------------------------------------------------------------
REVERT;
EXECUTE AS USER = 'pravin_kumar_login';

-- Should show REAL unmasked PII (not XXX-style masking)
SELECT ClientID, FullName, ContactNumber, Email, Address FROM Clients;
SELECT AgentID, FullName, ContactNumber, Email, CommissionRate FROM Agents;

-- Should show REAL unmasked agent data
SELECT AgentID, FullName, ContactNumber, Email, CommissionRate FROM Agents;

-- Should work: full direct access to any table
SELECT * FROM Properties;
SELECT * FROM Transactions;
SELECT * FROM MaintenanceRequests;
SELECT * FROM Users;

-- Should work: can decrypt PII directly using the key (not just through a procedure)
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;
SELECT ClientID, CONVERT(NVARCHAR(255), DECRYPTBYKEY(Address_Enc)) AS DecryptedAddress FROM Clients;
CLOSE SYMMETRIC KEY PIIKey;

REVERT;

-- =========================================================================
-- SECTION 11: VIEWS AND STORED PROCEDURES - AGENT OPERATIONS DEVELOPMENT
-- Purpose: Build the access-control layer for Agent Operations Dev, covering
-- Agents and Transactions. Follows the same proven pattern as Client Portal
-- Development (Section 7): basic info via View, decrypted PII via a
-- WITH EXECUTE AS OWNER procedure, writes via procedure, direct table
-- access denied entirely.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 11.1: View - basic (non-sensitive) agent info + performance summary
-- -------------------------------------------------------------------------
CREATE VIEW vw_AgentOps_Agents AS
SELECT
    a.AgentID,
    a.FullName,
    a.CommissionRate,
    a.JoinedDate,
    COUNT(t.TransactionID) AS TotalTransactions
FROM Agents a
LEFT JOIN Transactions t ON a.AgentID = t.AgentID
GROUP BY a.AgentID, a.FullName, a.CommissionRate, a.JoinedDate;
GO

GRANT SELECT ON vw_AgentOps_Agents TO AgentOpsDev;
GO


-- -------------------------------------------------------------------------
-- 11.2: View - transactions (no PII directly, safe to expose fully)
-- -------------------------------------------------------------------------
CREATE VIEW vw_AgentOps_Transactions AS
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
JOIN Properties p ON t.PropertyID = p.PropertyID
JOIN Agents a ON t.AgentID = a.AgentID;
GO

GRANT SELECT ON vw_AgentOps_Transactions TO AgentOpsDev;
GO


-- -------------------------------------------------------------------------
-- 11.3: Stored Procedure - controlled decrypted READ of agent PII
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_GetAgentContactInfo
    @AgentID INT = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

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


-- -------------------------------------------------------------------------
-- 11.4: Stored Procedure - controlled encrypted WRITE (register new agent)
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_RegisterNewAgent
    @FullName NVARCHAR(100),
    @ContactNumber NVARCHAR(20),
    @Email NVARCHAR(100),
    @CommissionRate DECIMAL(5,2)
WITH EXECUTE AS OWNER
AS
BEGIN
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


-- -------------------------------------------------------------------------
-- 11.5: Stored Procedure - log a new transaction (controlled write)
-- -------------------------------------------------------------------------
CREATE PROCEDURE sp_AddTransaction
    @PropertyID INT,
    @ClientID INT,
    @AgentID INT,
    @TransactionType NVARCHAR(50),
    @Amount DECIMAL(18,2)
AS
BEGIN
    INSERT INTO Transactions (PropertyID, ClientID, AgentID, TransactionType, Amount)
    VALUES (@PropertyID, @ClientID, @AgentID, @TransactionType, @Amount);
END;
GO

GRANT EXECUTE ON sp_AddTransaction TO AgentOpsDev;
GO


-- -------------------------------------------------------------------------
-- 11.6: Deny direct table access - forces all access through views/procedures
-- -------------------------------------------------------------------------
DENY SELECT, INSERT, UPDATE, DELETE ON Agents TO AgentOpsDev;
DENY SELECT, INSERT, UPDATE, DELETE ON Transactions TO AgentOpsDev;
GO


-- -------------------------------------------------------------------------
-- 11.7: Test - confirm the full access pattern works as intended
-- -------------------------------------------------------------------------
REVERT;
EXECUTE AS USER = 'ada_wong_login';

SELECT * FROM vw_AgentOps_Agents;              -- WORKS: basic info + performance
SELECT * FROM vw_AgentOps_Transactions;        -- WORKS: transaction details

SELECT SUSER_NAME() AS CurrentLogin;   -- should show 'ada_wong_login'

EXEC sp_GetAgentContactInfo;                   -- WORKS: decrypted PII for all agents

EXEC sp_RegisterNewAgent                       -- WORKS: encrypted write
    @FullName = 'Test Agent',
    @ContactNumber = '019-2222222',
    @Email = 'testagent@greenacres.com',
    @CommissionRate = 3.00;

EXEC sp_AddTransaction                         -- WORKS: transaction write
    @PropertyID = 6, @ClientID = 3, @AgentID = 2,
    @TransactionType = 'Rent', @Amount = 2500;

SELECT * FROM Agents;          -- DENIED: direct table access blocked
SELECT * FROM Transactions;    -- DENIED: direct table access blocked

REVERT;

SELECT AgentID, FullName, ContactNumber, Email, ContactNumber_Enc, Email_Enc 
FROM Agents;

-- =========================================================================
-- SECTION 12: BACKUPS
-- Purpose: Ensure Availability (the "A" in CIA) by implementing a proper
-- backup strategy covering Full, Differential, and Transaction Log
-- backups. Full backups create a complete copy of the database.
-- Differential backups capture only changes since the last full backup
-- (faster, smaller). Transaction log backups capture every transaction
-- since the last log backup, enabling point-in-time recovery.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 12.1: Switch to FULL recovery model
-- Required for transaction log backups. By default, new databases use
-- SIMPLE recovery model, which does NOT support log backups.
-- -------------------------------------------------------------------------
ALTER DATABASE GreenAcresEMS SET RECOVERY FULL;
GO


-- -------------------------------------------------------------------------
-- 12.2: Full Backup - complete copy of the entire database
-- This is the baseline that differential and log backups depend on.
-- -------------------------------------------------------------------------
BACKUP DATABASE GreenAcresEMS
TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Full.bak'
WITH INIT, NAME = 'GreenAcresEMS-Full Database Backup';
GO


-- -------------------------------------------------------------------------
-- 12.3: Differential Backup - only changes since the last FULL backup
-- Requires the full backup above to already exist.
-- -------------------------------------------------------------------------
BACKUP DATABASE GreenAcresEMS
TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Diff.bak'
WITH DIFFERENTIAL, NAME = 'GreenAcresEMS-Differential Backup';
GO


-- -------------------------------------------------------------------------
-- 12.4: Transaction Log Backup - all transactions since the last backup
-- (full, differential, or log). Enables point-in-time recovery.
-- -------------------------------------------------------------------------
BACKUP LOG GreenAcresEMS
TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Log.trn'
WITH NAME = 'GreenAcresEMS-Transaction Log Backup';
GO


-- -------------------------------------------------------------------------
-- 12.5: Verify backups were created - check backup history
-- -------------------------------------------------------------------------
SELECT
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    CASE bs.type
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Transaction Log'
    END AS BackupType,
    bmf.physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'GreenAcresEMS'
ORDER BY bs.backup_start_date DESC;


-- =========================================================================
-- 12.6: RESTORE TEST - verify the Full backup is valid and restorable
-- Purpose: Prove backups aren't just files sitting on disk, but genuinely
-- restorable. Restoring to a NEW database name (not overwriting the
-- original) keeps this safe to test without risking your live data.
-- =========================================================================

-- Step 1: Check the logical file names inside the backup (needed for MOVE)
RESTORE FILELISTONLY
FROM DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Full.bak';

-- Step 2: Restore the Full backup to a NEW database (safe test, doesn't
-- touch your original GreenAcresEMS database)
RESTORE DATABASE GreenAcresEMS_RestoreTest
FROM DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Full.bak'
WITH
    MOVE 'GreenAcresEMS' TO 'C:\GreenAcresBackups\GreenAcresEMS_RestoreTest.mdf',
    MOVE 'GreenAcresEMS_log' TO 'C:\GreenAcresBackups\GreenAcresEMS_RestoreTest_log.ldf',
    RECOVERY;
GO

USE GreenAcresEMS_RestoreTest;
GO

SELECT * FROM Clients;
SELECT * FROM Properties;

-- =========================================================================
-- SECTION 13: SERVER AUDITING AND DATABASE AUDITING
-- Purpose: Track security-relevant events at two levels. Server Audit
-- captures instance-wide events (failed logins, permission/role changes)
-- that apply across the whole SQL Server, not just one database.
-- Database Audit Specification captures activity on specific sensitive
-- objects within GreenAcresEMS (e.g. who read or changed Clients/Agents
-- PII), which is more granular and directly relevant to data protection.
-- =========================================================================

USE master;
GO

-- -------------------------------------------------------------------------
-- 13.1: Create the Server Audit object - defines WHERE audit logs are
-- written. Both server-level and database-level specifications attach
-- to this same audit object.
-- -------------------------------------------------------------------------
CREATE SERVER AUDIT GreenAcres_ServerAudit
TO FILE (FILEPATH = 'C:\GreenAcresAudits\');
GO

-- Enable the audit
ALTER SERVER AUDIT GreenAcres_ServerAudit WITH (STATE = ON);
GO


-- -------------------------------------------------------------------------
-- 13.2: Server Audit Specification - captures instance-wide security
-- events: failed logins (possible brute-force attempts) and any changes
-- to server-level roles/permissions.
-- -------------------------------------------------------------------------
CREATE SERVER AUDIT SPECIFICATION GreenAcres_ServerAuditSpec
FOR SERVER AUDIT GreenAcres_ServerAudit
ADD (FAILED_LOGIN_GROUP),
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP)
WITH (STATE = ON);
GO


-- -------------------------------------------------------------------------
-- 13.3: Database Audit Specification - captures activity on sensitive
-- tables specifically within GreenAcresEMS. Tracks SELECT (who READ PII),
-- and INSERT/UPDATE/DELETE (who CHANGED data) on Clients and Agents,
-- by anyone (PUBLIC covers all users/roles).
-- -------------------------------------------------------------------------
USE GreenAcresEMS;
GO

CREATE DATABASE AUDIT SPECIFICATION GreenAcres_DBAuditSpec
FOR SERVER AUDIT GreenAcres_ServerAudit
ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Clients BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Agents BY PUBLIC),
ADD (UPDATE ON dbo.Properties BY PUBLIC)
WITH (STATE = ON);
GO


-- -------------------------------------------------------------------------
-- 13.4: Test - generate some activity, then read the audit log
-- -------------------------------------------------------------------------

-- Trigger a database-level audit event (an authorized SELECT on Clients, as admin)
SELECT ClientID, FullName FROM Clients;

-- Trigger a failed login event (deliberately wrong password, for testing)
-- Run this from a NEW connection/query window with SQL Login using
-- 'leon_kennedy_login' and an intentionally WRONG password, then come back here.

-- Read the audit log to see what was captured
SELECT
    event_time,
    action_id,
    succeeded,
    server_principal_name,
    database_name,
    object_name,
    statement
FROM sys.fn_get_audit_file('C:\GreenAcresAudits\*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;


-- =========================================================================
-- SECTION 14: TRIGGERS
-- Purpose: Implement two categories of triggers as required by the
-- assignment - AUDITING triggers (log every change to sensitive tables
-- into a dedicated AuditLog table) and OPERATIONAL triggers (enforce
-- business rules automatically, independent of which role or procedure
-- performs the action).
-- =========================================================================

USE GreenAcresEMS;
GO

-- -------------------------------------------------------------------------
-- 14.1: Create the AuditLog table (referenced since Section 10, now built)
-- -------------------------------------------------------------------------
CREATE TABLE AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100),
    Operation NVARCHAR(10),          -- INSERT / UPDATE / DELETE
    RecordID INT,
    ChangedBy NVARCHAR(100) DEFAULT SUSER_SNAME(),
    ChangedDate DATETIME DEFAULT GETDATE(),
    OldValue NVARCHAR(MAX),
    NewValue NVARCHAR(MAX)
);
GO

-- Grant DBAdminRole read-only access to review audit history (pending
-- from Section 10.2, now that the table finally exists)
GRANT SELECT ON AuditLog TO DBAdminRole;
GO


-- -------------------------------------------------------------------------
-- 14.2: AUDITING TRIGGER - logs every UPDATE on Properties into AuditLog
-- Captures the old and new values as JSON, so you can see exactly what
-- changed, when, and by whom.
-- -------------------------------------------------------------------------
CREATE TRIGGER trg_Properties_AuditUpdate
ON Properties
AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditLog (TableName, Operation, RecordID, OldValue, NewValue)
    SELECT
        'Properties',
        'UPDATE',
        i.PropertyID,
        (SELECT d.PropertyID, d.PropertyName, d.Address, d.City, d.State, d.Price, d.Status
         FROM deleted d WHERE d.PropertyID = i.PropertyID FOR JSON AUTO) AS OldValue,
        (SELECT i2.PropertyID, i2.PropertyName, i2.Address, i2.City, i2.State, i2.Price, i2.Status
         FROM inserted i2 WHERE i2.PropertyID = i.PropertyID FOR JSON AUTO) AS NewValue
    FROM inserted i
    JOIN deleted d ON i.PropertyID = d.PropertyID;
END;
GO


-- -------------------------------------------------------------------------
-- 14.3: AUDITING TRIGGER - logs every INSERT on Clients into AuditLog
-- Demonstrates auditing on a different table and a different operation
-- type (INSERT rather than UPDATE), showing breadth of coverage.
-- -------------------------------------------------------------------------
CREATE TRIGGER trg_Clients_AuditInsert
ON Clients
AFTER INSERT
AS
BEGIN
    INSERT INTO AuditLog (TableName, Operation, RecordID, NewValue)
    SELECT
        'Clients',
        'INSERT',
        i.ClientID,
        (SELECT i2.ClientID, i2.FullName, i2.RegisteredDate
         FROM inserted i2 WHERE i2.ClientID = i.ClientID FOR JSON AUTO) AS NewValue
    FROM inserted i;
END;
GO


-- -------------------------------------------------------------------------
-- 14.4: OPERATIONAL TRIGGER - automatically updates Property Status when
-- a Sale transaction is recorded. This is a business rule enforced at
-- the database level, independent of whichever procedure or role
-- inserted the transaction - it always fires.
-- -------------------------------------------------------------------------
CREATE TRIGGER trg_Transaction_UpdatePropertyStatus
ON Transactions
AFTER INSERT
AS
BEGIN
    UPDATE p
    SET p.Status = 'Sold',
        p.ModifiedDate = GETDATE(),
        p.ModifiedBy = SUSER_SNAME()
    FROM Properties p
    JOIN inserted i ON p.PropertyID = i.PropertyID
    WHERE i.TransactionType = 'Sale';

    UPDATE p
    SET p.Status = 'Rented',
        p.ModifiedDate = GETDATE(),
        p.ModifiedBy = SUSER_SNAME()
    FROM Properties p
    JOIN inserted i ON p.PropertyID = i.PropertyID
    WHERE i.TransactionType = 'Rent';
END;
GO


-- -------------------------------------------------------------------------
-- 14.5: OPERATIONAL TRIGGER - prevent maintenance requests from being
-- logged against a property that has been Sold (business rule: once
-- sold, the previous owner's maintenance issues are no longer the
-- company's responsibility to track)
-- -------------------------------------------------------------------------
CREATE TRIGGER trg_MaintenanceRequest_PreventOnSoldProperty
ON MaintenanceRequests
INSTEAD OF INSERT
AS
BEGIN
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


-- -------------------------------------------------------------------------
-- 14.6: Test all triggers
-- -------------------------------------------------------------------------

-- Test 14.2/14.4: insert a Sale transaction, should auto-update Property
-- status AND log the change via the Properties audit trigger
EXEC sp_AddTransaction @PropertyID = 5, @ClientID = 2, @AgentID = 3, @TransactionType = 'Sale', @Amount = 480000;

-- Check: Property 5 should now show Status = 'Sold'
SELECT PropertyID, PropertyName, Status, ModifiedDate, ModifiedBy FROM Properties WHERE PropertyID = 5;

-- Check: AuditLog should have a new entry for this change
SELECT * FROM AuditLog ORDER BY ChangedDate DESC;

-- Test 14.3: insert a new client, should log via the Clients audit trigger
EXEC sp_RegisterNewClient @FullName = 'Trigger Test Client', @ContactNumber = '019-9999999', @Email = 'triggertest@gmail.com', @Address = '99 Jalan Trigger, Shah Alam';

SELECT * FROM AuditLog WHERE TableName = 'Clients' ORDER BY ChangedDate DESC;

-- Test 14.5: try adding a maintenance request to the now-Sold Property 5 - should FAIL
EXEC sp_AddMaintenanceRequest @PropertyID = 5, @RequestDetails = 'Test - should be blocked since property is Sold';

-- =========================================================================
-- SECTION 15: BONUS - ADDITIONAL AUDITING TRIGGERS
-- Purpose: Extend audit coverage beyond Properties/Clients to Agents and
-- Transactions, demonstrating comprehensive auditing across all sensitive
-- and business-critical tables, not just a minimal subset.
-- =========================================================================

USE GreenAcresEMS;
GO

-- -------------------------------------------------------------------------
-- 15.1: AUDITING TRIGGER - logs every INSERT on Agents into AuditLog
-- -------------------------------------------------------------------------
CREATE TRIGGER trg_Agents_AuditInsert
ON Agents
AFTER INSERT
AS
BEGIN
    INSERT INTO AuditLog (TableName, Operation, RecordID, NewValue)
    SELECT
        'Agents',
        'INSERT',
        i.AgentID,
        (SELECT i2.AgentID, i2.FullName, i2.CommissionRate, i2.JoinedDate
         FROM inserted i2 WHERE i2.AgentID = i.AgentID FOR JSON AUTO) AS NewValue
    FROM inserted i;
END;
GO


-- -------------------------------------------------------------------------
-- 15.2: AUDITING TRIGGER - logs every INSERT on Transactions into AuditLog
-- Transactions are financially significant, so every new transaction
-- should be traceable in the audit history.
-- -------------------------------------------------------------------------
CREATE TRIGGER trg_Transactions_AuditInsert
ON Transactions
AFTER INSERT
AS
BEGIN
    INSERT INTO AuditLog (TableName, Operation, RecordID, NewValue)
    SELECT
        'Transactions',
        'INSERT',
        i.TransactionID,
        (SELECT i2.TransactionID, i2.PropertyID, i2.ClientID, i2.AgentID, i2.TransactionType, i2.Amount
         FROM inserted i2 WHERE i2.TransactionID = i.TransactionID FOR JSON AUTO) AS NewValue
    FROM inserted i;
END;
GO


-- -------------------------------------------------------------------------
-- 15.3: Test both new triggers
-- -------------------------------------------------------------------------

-- Test 15.1: register a new agent, should log via the Agents audit trigger
EXEC sp_RegisterNewAgent @FullName = 'Audit Test Agent', @ContactNumber = '012-3334455', @Email = 'audittest@greenacres.com', @CommissionRate = 2.80;

SELECT * FROM AuditLog WHERE TableName = 'Agents' ORDER BY ChangedDate DESC;

-- Test 15.2: add a new transaction, should log via the Transactions audit trigger
EXEC sp_AddTransaction @PropertyID = 3, @ClientID = 4, @AgentID = 1, @TransactionType = 'Rent', @Amount = 1800;

SELECT * FROM AuditLog WHERE TableName = 'Transactions' ORDER BY ChangedDate DESC;

-- =========================================================================
-- SECTION 16: FINAL CLEANUP
-- Purpose: Check for and remove any leftover temporary permissions granted
-- during development/troubleshooting that shouldn't remain in the final
-- submission, clean up test/junk data, and take a final backup reflecting
-- the fully completed database.
-- =========================================================================

USE GreenAcresEMS;
GO

-- -------------------------------------------------------------------------
-- 16.1: Check for any leftover grants that shouldn't be there
-- -------------------------------------------------------------------------
SELECT 
    dp.name AS RoleName,
    o.name AS TableName,
    perm.permission_name,
    perm.state_desc
FROM sys.database_permissions perm
JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o ON perm.major_id = o.object_id
WHERE dp.name IN ('ClientPortalDev', 'PropertyMgmtDev', 'AnalyticsTeam', 'AgentOpsDev')
AND perm.state_desc = 'GRANT'
AND o.name IN ('Clients', 'Agents', 'Properties', 'Transactions', 'MaintenanceRequests')
ORDER BY dp.name;

DELETE FROM Clients WHERE ClientID IN (11, 12, 13);

SELECT * FROM Clients;
SELECT * FROM Agents;
SELECT * FROM Transactions;
SELECT * FROM MaintenanceRequests;

--Drop restoredb
USE master;
GO

DROP DATABASE GreenAcresEMS_RestoreTest;
GO
SELECT name FROM sys.databases WHERE name LIKE 'GreenAcres%';


-- Update Client name from test
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

-- Update ClientID 14
UPDATE Clients
SET FullName = 'Nabila Hassan',
    ContactNumber = '017-8834521',
    Email = 'nabila.hassan@gmail.com',
    Address = '5 Jalan Bukit Indah, Taman Bukit Indah, 47000 Sungai Buloh, Selangor',
    ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), '017-8834521'),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), 'nabila.hassan@gmail.com'),
    Address_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), '5 Jalan Bukit Indah, Taman Bukit Indah, 47000 Sungai Buloh, Selangor')
WHERE ClientID = 14;

-- Update ClientID 15
UPDATE Clients
SET FullName = 'Rayyan Firdaus',
    ContactNumber = '013-4567892',
    Email = 'rayyan.firdaus@yahoo.com',
    Address = '8 Jalan Meranti, Taman Meranti Jaya, 47120 Puchong, Selangor',
    ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), '013-4567892'),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), 'rayyan.firdaus@yahoo.com'),
    Address_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), '8 Jalan Meranti, Taman Meranti Jaya, 47120 Puchong, Selangor')
WHERE ClientID = 15;

CLOSE SYMMETRIC KEY PIIKey;


SELECT ClientID, FullName, ContactNumber, Email, Address, ContactNumber_Enc, Email_Enc, Address_Enc FROM Clients WHERE ClientID IN (14, 15);


-- Update Agent name from test
OPEN SYMMETRIC KEY PIIKey DECRYPTION BY CERTIFICATE PIICert;

UPDATE Agents
SET FullName = 'Farah Adilah',
    ContactNumber = '019-7723456',
    Email = 'farah.adilah@greenacres.com',
    ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), '019-7723456'),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), 'farah.adilah@greenacres.com')
WHERE AgentID = 6;

UPDATE Agents
SET FullName = 'Kishen Raj',
    ContactNumber = '016-3345678',
    Email = 'kishen.raj@greenacres.com',
    ContactNumber_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), '016-3345678'),
    Email_Enc = ENCRYPTBYKEY(KEY_GUID('PIIKey'), 'kishen.raj@greenacres.com')
WHERE AgentID = 7;

CLOSE SYMMETRIC KEY PIIKey;

SELECT AgentID, FullName, ContactNumber, Email, CommissionRate FROM Agents;


SELECT ClientID, FullName, ContactNumber, Email, Address FROM Clients ORDER BY ClientID;
SELECT AgentID, FullName, ContactNumber, Email, CommissionRate FROM Agents ORDER BY AgentID;
SELECT * FROM Transactions ORDER BY TransactionID;
SELECT * FROM MaintenanceRequests ORDER BY RequestID;


BACKUP DATABASE GreenAcresEMS
TO DISK = 'C:\GreenAcresBackups\GreenAcresEMS_Final_Full.bak'
WITH INIT, NAME = 'GreenAcresEMS-Final Submission Backup';
GO


--17 Query For documentation:

--Step 1 — Data Dictionary query 
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable,
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


-- Step 2 — Authorization Matrix query
SELECT 
    dp.name AS RoleOrUser,
    ISNULL(o.name, 'N/A - Certificate/Key') AS ObjectName,
    o.type_desc AS ObjectType,
    perm.permission_name AS Permission,
    perm.state_desc AS GrantOrDeny
FROM sys.database_permissions perm
JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o ON perm.major_id = o.object_id
WHERE dp.type = 'R'  -- R = database Role
ORDER BY dp.name, o.name, perm.permission_name;

