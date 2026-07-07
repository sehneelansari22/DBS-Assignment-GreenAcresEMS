
--Create the database
USE master;
GO

CREATE DATABASE GreenAcresEMS;
GO

USE GreenAcresEMS;
GO

--Create tables

--Table 1: Properties
CREATE TABLE dbo.Properties
(
    PropertyID INT IDENTITY(1,1)
        CONSTRAINT PK_Properties PRIMARY KEY,

    PropertyName NVARCHAR(150) NOT NULL,

    PropertyType NVARCHAR(30) NOT NULL
        CONSTRAINT CK_Properties_PropertyType
        CHECK (PropertyType IN
        ('Apartment', 'Condominium', 'Terrace House',
         'Semi-D', 'Bungalow', 'Commercial')),

    Address NVARCHAR(255) NOT NULL,

    City NVARCHAR(100) NOT NULL,

    State NVARCHAR(100) NOT NULL,

    Price DECIMAL(18,2) NOT NULL
        CONSTRAINT CK_Properties_Price
        CHECK (Price > 0),

    Status NVARCHAR(30) NOT NULL
        CONSTRAINT DF_Properties_Status
        DEFAULT ('Available')
        CONSTRAINT CK_Properties_Status
        CHECK (Status IN
        ('Available', 'Reserved', 'Sold',
         'Rented', 'Under Maintenance')),

    CreatedDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Properties_CreatedDate
        DEFAULT (SYSDATETIME()),

    CONSTRAINT UQ_Properties_Address
        UNIQUE (Address)
);
GO

--Table 2: CLients
CREATE TABLE dbo.Clients
(
    ClientID INT IDENTITY(1,1)
        CONSTRAINT PK_Clients PRIMARY KEY,

    FullName NVARCHAR(100) NOT NULL,

    ContactNumber NVARCHAR(20) NOT NULL,

    Email NVARCHAR(100) NOT NULL,

    Address NVARCHAR(255) NOT NULL,

    ClientStatus NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Clients_Status
        DEFAULT ('Active')
        CONSTRAINT CK_Clients_Status
        CHECK (ClientStatus IN ('Active', 'Inactive')),

    RegisteredDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Clients_RegisteredDate
        DEFAULT (SYSDATETIME()),

    CONSTRAINT UQ_Clients_Email
        UNIQUE (Email),

    CONSTRAINT UQ_Clients_ContactNumber
        UNIQUE (ContactNumber),

    CONSTRAINT CK_Clients_EmailFormat
        CHECK (Email LIKE '%_@_%._%')
);
GO
--Table 3: Agents
CREATE TABLE dbo.Agents
(
    AgentID INT IDENTITY(1,1)
        CONSTRAINT PK_Agents PRIMARY KEY,

    FullName NVARCHAR(100) NOT NULL,

    ContactNumber NVARCHAR(20) NOT NULL,

    Email NVARCHAR(100) NOT NULL,

    CommissionRate DECIMAL(5,2) NOT NULL
        CONSTRAINT CK_Agents_CommissionRate
        CHECK (CommissionRate BETWEEN 0 AND 100),

    AgentStatus NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Agents_Status
        DEFAULT ('Active')
        CONSTRAINT CK_Agents_Status
        CHECK (AgentStatus IN ('Active', 'Inactive')),

    JoinedDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Agents_JoinedDate
        DEFAULT (SYSDATETIME()),

    CONSTRAINT UQ_Agents_Email
        UNIQUE (Email),

    CONSTRAINT UQ_Agents_ContactNumber
        UNIQUE (ContactNumber),

    CONSTRAINT CK_Agents_EmailFormat
        CHECK (Email LIKE '%_@_%._%')
);
GO

--Table 4: Transactions
CREATE TABLE dbo.Transactions
(
    TransactionID INT IDENTITY(1,1)
        CONSTRAINT PK_Transactions PRIMARY KEY,

    PropertyID INT NOT NULL,

    ClientID INT NOT NULL,

    AgentID INT NOT NULL,

    TransactionType NVARCHAR(20) NOT NULL
        CONSTRAINT CK_Transactions_Type
        CHECK (TransactionType IN ('Sale', 'Rent')),

    TransactionDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Transactions_Date
        DEFAULT (SYSDATETIME()),

    Amount DECIMAL(18,2) NOT NULL
        CONSTRAINT CK_Transactions_Amount
        CHECK (Amount > 0),

    TransactionStatus NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Transactions_Status
        DEFAULT ('Completed')
        CONSTRAINT CK_Transactions_Status
        CHECK (TransactionStatus IN
        ('Pending', 'Completed', 'Cancelled')),

    CONSTRAINT FK_Transactions_Properties
        FOREIGN KEY (PropertyID)
        REFERENCES dbo.Properties(PropertyID),

    CONSTRAINT FK_Transactions_Clients
        FOREIGN KEY (ClientID)
        REFERENCES dbo.Clients(ClientID),

    CONSTRAINT FK_Transactions_Agents
        FOREIGN KEY (AgentID)
        REFERENCES dbo.Agents(AgentID)
);
GO

--Table 5: MaintenanceRequests
CREATE TABLE dbo.MaintenanceRequests
(
    RequestID INT IDENTITY(1,1)
        CONSTRAINT PK_MaintenanceRequests PRIMARY KEY,

    PropertyID INT NOT NULL,

    RequestDetails NVARCHAR(1000) NOT NULL,

    Priority NVARCHAR(20) NOT NULL
        CONSTRAINT DF_MaintenanceRequests_Priority
        DEFAULT ('Medium')
        CONSTRAINT CK_MaintenanceRequests_Priority
        CHECK (Priority IN
        ('Low', 'Medium', 'High', 'Critical')),

    RequestDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_MaintenanceRequests_Date
        DEFAULT (SYSDATETIME()),

    Status NVARCHAR(30) NOT NULL
        CONSTRAINT DF_MaintenanceRequests_Status
        DEFAULT ('Pending')
        CONSTRAINT CK_MaintenanceRequests_Status
        CHECK (Status IN
        ('Pending', 'In Progress', 'Completed', 'Rejected')),

    CONSTRAINT FK_MaintenanceRequests_Properties
        FOREIGN KEY (PropertyID)
        REFERENCES dbo.Properties(PropertyID)
);
GO

--Table 6: SystemUsers
--Passwords are stored as hashes, not plain text
CREATE TABLE dbo.SystemUsers
(
    SystemUserID INT IDENTITY(1,1)
        CONSTRAINT PK_SystemUsers PRIMARY KEY,

    Username NVARCHAR(60) NOT NULL,

    PasswordSalt UNIQUEIDENTIFIER NOT NULL,

    PasswordHash VARBINARY(64) NOT NULL,

    UserCategory NVARCHAR(40) NOT NULL
        CONSTRAINT CK_SystemUsers_Category
        CHECK (UserCategory IN
        ('PropertyDeveloper',
         'ClientPortalDeveloper',
         'AnalyticsDeveloper',
         'Auditor',
         'DBA')),

    IsActive BIT NOT NULL
        CONSTRAINT DF_SystemUsers_IsActive
        DEFAULT (1),

    CreatedDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_SystemUsers_CreatedDate
        DEFAULT (SYSDATETIME()),

    CONSTRAINT UQ_SystemUsers_Username
        UNIQUE (Username)
);
GO

--Table 7: PropertyDocuments
CREATE TABLE dbo.PropertyDocuments
(
    DocumentID INT IDENTITY(1,1)
        CONSTRAINT PK_PropertyDocuments PRIMARY KEY,

    PropertyID INT NOT NULL,

    DocumentName NVARCHAR(150) NOT NULL,

    DocumentType NVARCHAR(40) NOT NULL
        CONSTRAINT CK_PropertyDocuments_Type
        CHECK (DocumentType IN
        ('Title Deed',
         'Tenancy Agreement',
         'Inspection Report',
         'Maintenance Invoice',
         'Other')),

    DocumentPath NVARCHAR(500) NOT NULL,

    Classification NVARCHAR(20) NOT NULL
        CONSTRAINT DF_PropertyDocuments_Classification
        DEFAULT ('Confidential')
        CONSTRAINT CK_PropertyDocuments_Classification
        CHECK (Classification IN
        ('Public', 'Internal', 'Confidential', 'Restricted')),

    UploadedDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_PropertyDocuments_UploadedDate
        DEFAULT (SYSDATETIME()),

    CONSTRAINT FK_PropertyDocuments_Properties
        FOREIGN KEY (PropertyID)
        REFERENCES dbo.Properties(PropertyID),

    CONSTRAINT UQ_PropertyDocuments_Path
        UNIQUE (DocumentPath)
);
GO

--Table 8: MaintenanceHistory
CREATE TABLE dbo.MaintenanceHistory
(
    MaintenanceHistoryID INT IDENTITY(1,1)
        CONSTRAINT PK_MaintenanceHistory PRIMARY KEY,

    RequestID INT NOT NULL,

    OldStatus NVARCHAR(30) NULL,

    NewStatus NVARCHAR(30) NOT NULL,

    ChangedBy SYSNAME NOT NULL
        CONSTRAINT DF_MaintenanceHistory_ChangedBy
        DEFAULT (SUSER_SNAME()),

    ChangedDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_MaintenanceHistory_ChangedDate
        DEFAULT (SYSDATETIME()),

    Remarks NVARCHAR(500) NULL,

    CONSTRAINT FK_MaintenanceHistory_Request
        FOREIGN KEY (RequestID)
        REFERENCES dbo.MaintenanceRequests(RequestID)
);
GO

--Table 9: Transaction History
CREATE TABLE dbo.TransactionHistory
(
    TransactionHistoryID INT IDENTITY(1,1)
        CONSTRAINT PK_TransactionHistory PRIMARY KEY,

    TransactionID INT NOT NULL,

    ActionType NVARCHAR(20) NOT NULL
        CONSTRAINT CK_TransactionHistory_ActionType
        CHECK (ActionType IN
        ('CREATED', 'UPDATED', 'CANCELLED')),

    ActionBy SYSNAME NOT NULL
        CONSTRAINT DF_TransactionHistory_ActionBy
        DEFAULT (SUSER_SNAME()),

    ActionDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_TransactionHistory_ActionDate
        DEFAULT (SYSDATETIME()),

    Notes NVARCHAR(500) NULL,

    CONSTRAINT FK_TransactionHistory_Transaction
        FOREIGN KEY (TransactionID)
        REFERENCES dbo.Transactions(TransactionID)
);
GO

--Create Index for performance
CREATE INDEX IX_Properties_Status_City
ON dbo.Properties (Status, City);
GO

CREATE INDEX IX_Transactions_PropertyID
ON dbo.Transactions (PropertyID);
GO

CREATE INDEX IX_Transactions_TransactionDate
ON dbo.Transactions (TransactionDate);
GO

CREATE INDEX IX_MaintenanceRequests_PropertyID_Status
ON dbo.MaintenanceRequests (PropertyID, Status);
GO

--Insert Data / Properties
INSERT INTO dbo.Properties
(PropertyName, PropertyType, Address, City, State, Price, Status)
VALUES
('Greenview Residence A-12', 'Apartment',
 '12 Jalan Damai, Taman Greenview', 'Kuala Lumpur',
 'WP Kuala Lumpur', 420000.00, 'Available'),

('Lakefront Condo B-08', 'Condominium',
 '8 Persiaran Tasik, Lakefront', 'Shah Alam',
 'Selangor', 680000.00, 'Sold'),

('Seri Murni Terrace 22', 'Terrace House',
 '22 Jalan Murni 3, Seri Murni', 'Kajang',
 'Selangor', 550000.00, 'Rented'),

('Bukit Indah Bungalow 5', 'Bungalow',
 '5 Jalan Indah, Bukit Indah', 'Johor Bahru',
 'Johor', 1250000.00, 'Under Maintenance'),

('MetroBiz Shoplot 17', 'Commercial',
 '17 Jalan Metro, MetroBiz', 'Petaling Jaya',
 'Selangor', 950000.00, 'Available'),

('Sunrise Apartment C-09', 'Apartment',
 '9 Jalan Sunrise, Taman Ceria', 'Subang Jaya',
 'Selangor', 390000.00, 'Reserved');
GO

--Clients Data
INSERT INTO dbo.Clients
(FullName, ContactNumber, Email, Address)
VALUES
('Aina Rahman', '012-5551001',
 'aina.rahman@example.com', 'Kuala Lumpur'),

('Daniel Lim', '013-5551002',
 'daniel.lim@example.com', 'Shah Alam'),

('Kavitha Nair', '014-5551003',
 'kavitha.nair@example.com', 'Kajang'),

('Muhammad Irfan', '016-5551004',
 'irfan@example.com', 'Petaling Jaya'),

('Siti Hajar', '017-5551005',
 'siti.hajar@example.com', 'Johor Bahru');
GO

--Agents Data
INSERT INTO dbo.Agents
(FullName, ContactNumber, Email, CommissionRate)
VALUES
('Amir Hamzah', '018-4442001',
 'amir.hamzah@greenacres.com', 3.50),

('Cheryl Tan', '018-4442002',
 'cheryl.tan@greenacres.com', 4.00),

('Raj Kumar', '018-4442003',
 'raj.kumar@greenacres.com', 3.75);
GO

--Transaction Data
INSERT INTO dbo.Transactions
(PropertyID, ClientID, AgentID, TransactionType,
 Amount, TransactionStatus)
VALUES
(2, 1, 1, 'Sale', 680000.00, 'Completed'),

(3, 2, 2, 'Rent', 24000.00, 'Completed'),

(6, 3, 3, 'Sale', 390000.00, 'Pending');
GO

--Maintenance Requests
INSERT INTO dbo.MaintenanceRequests
(PropertyID, RequestDetails, Priority, Status)
VALUES
(4, 'Roof leakage requires urgent inspection.',
 'High', 'In Progress'),

(3, 'Replace damaged kitchen cabinet hinge.',
 'Low', 'Pending'),

(1, 'Inspect water pressure issue in bathroom.',
 'Medium', 'Pending');
GO

--Property Documents Data
INSERT INTO dbo.PropertyDocuments
(PropertyID, DocumentName, DocumentType,
 DocumentPath, Classification)
VALUES
(1, 'Inspection Report - Greenview A12',
 'Inspection Report',
 '/documents/property1/inspection-report.pdf',
 'Internal'),

(2, 'Title Deed - Lakefront B08',
 'Title Deed',
 '/documents/property2/title-deed.pdf',
 'Restricted'),

(3, 'Tenancy Agreement - Seri Murni 22',
 'Tenancy Agreement',
 '/documents/property3/tenancy-agreement.pdf',
 'Confidential');
GO

--Insert Hashed System Users
--Hashed System user password
DECLARE @Salt1 UNIQUEIDENTIFIER = NEWID();
DECLARE @Salt2 UNIQUEIDENTIFIER = NEWID();
DECLARE @Salt3 UNIQUEIDENTIFIER = NEWID();
DECLARE @Salt4 UNIQUEIDENTIFIER = NEWID();
DECLARE @Salt5 UNIQUEIDENTIFIER = NEWID();

INSERT INTO dbo.SystemUsers
(Username, PasswordSalt, PasswordHash, UserCategory)
VALUES
(
    'property_dev_app',
    @Salt1,
    HASHBYTES(
        'SHA2_256',
        CONCAT('PropertyDev@123', '|', CONVERT(NVARCHAR(36), @Salt1))
    ),
    'PropertyDeveloper'
),
(
    'client_portal_app',
    @Salt2,
    HASHBYTES(
        'SHA2_256',
        CONCAT('ClientPortal@123', '|', CONVERT(NVARCHAR(36), @Salt2))
    ),
    'ClientPortalDeveloper'
),
(
    'analytics_app',
    @Salt3,
    HASHBYTES(
        'SHA2_256',
        CONCAT('Analytics@123', '|', CONVERT(NVARCHAR(36), @Salt3))
    ),
    'AnalyticsDeveloper'
),
(
    'auditor_app',
    @Salt4,
    HASHBYTES(
        'SHA2_256',
        CONCAT('Auditor@123', '|', CONVERT(NVARCHAR(36), @Salt4))
    ),
    'Auditor'
),
(
    'dba_app',
    @Salt5,
    HASHBYTES(
        'SHA2_256',
        CONCAT('DBA@123', '|', CONVERT(NVARCHAR(36), @Salt5))
    ),
    'DBA'
);
GO

--Check the password
SELECT
    SystemUserID,
    Username,
    PasswordSalt,
    PasswordHash,
    UserCategory,
    IsActive
FROM dbo.SystemUsers;
GO

--Secure Views
--View 1 : Available Properties
SELECT
    SystemUserID,
    Username,
    PasswordSalt,
    PasswordHash,
    UserCategory,
    IsActive
FROM dbo.SystemUsers;
GO

--View 2 : masked CLient Details
CREATE VIEW dbo.vw_MaskedClientDetails
AS
SELECT
    ClientID,

    CONCAT(
        LEFT(FullName, 1),
        REPLICATE('*',
            CASE
                WHEN LEN(FullName) > 2 THEN LEN(FullName) - 2
                ELSE 1
            END),
        RIGHT(FullName, 1)
    ) AS MaskedFullName,

    CONCAT(
        LEFT(ContactNumber, 3),
        '-XXXX',
        RIGHT(ContactNumber, 2)
    ) AS MaskedContactNumber,

    CONCAT(
        LEFT(Email, 2),
        '***',
        SUBSTRING(Email, CHARINDEX('@', Email), LEN(Email))
    ) AS MaskedEmail,

    ClientStatus,
    RegisteredDate
FROM dbo.Clients;
GO

--VIew 3 : Analytics Transaction Summary
CREATE VIEW dbo.vw_AnalyticsTransactionSummary
AS
SELECT
    YEAR(T.TransactionDate) AS TransactionYear,
    MONTH(T.TransactionDate) AS TransactionMonth,
    P.City,
    P.State,
    T.TransactionType,
    T.TransactionStatus,
    COUNT(*) AS TotalTransactions,
    SUM(T.Amount) AS TotalAmount,
    AVG(T.Amount) AS AverageAmount
FROM dbo.Transactions AS T
INNER JOIN dbo.Properties AS P
    ON T.PropertyID = P.PropertyID
GROUP BY
    YEAR(T.TransactionDate),
    MONTH(T.TransactionDate),
    P.City,
    P.State,
    T.TransactionType,
    T.TransactionStatus;
GO

--View 4 : Maintenance Overview
CREATE VIEW dbo.vw_MaintenanceOverview
AS
SELECT
    M.RequestID,
    P.PropertyID,
    P.PropertyName,
    P.City,
    M.RequestDetails,
    M.Priority,
    M.RequestDate,
    M.Status
FROM dbo.MaintenanceRequests AS M
INNER JOIN dbo.Properties AS P
    ON M.PropertyID = P.PropertyID;
GO

--Test The Views
SELECT * FROM dbo.vw_AvailableProperties;
SELECT * FROM dbo.vw_MaskedClientDetails;
SELECT * FROM dbo.vw_AnalyticsTransactionSummary;
SELECT * FROM dbo.vw_MaintenanceOverview;
GO

--Stored Produces
--Procedure 1: Add Property
CREATE PROCEDURE dbo.usp_AddProperty
    @PropertyName NVARCHAR(150),
    @PropertyType NVARCHAR(30),
    @Address NVARCHAR(255),
    @City NVARCHAR(100),
    @State NVARCHAR(100),
    @Price DECIMAL(18,2),
    @Status NVARCHAR(30) = 'Available'
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @Price <= 0
            THROW 50001, 'Property price must be greater than zero.', 1;

        INSERT INTO dbo.Properties
        (
            PropertyName,
            PropertyType,
            Address,
            City,
            State,
            Price,
            Status
        )
        VALUES
        (
            @PropertyName,
            @PropertyType,
            @Address,
            @City,
            @State,
            @Price,
            @Status
        );

        SELECT
            'Property added successfully.' AS Message,
            SCOPE_IDENTITY() AS NewPropertyID;
    END TRY

    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

--Procedure 2: Update Property Status
CREATE PROCEDURE dbo.usp_UpdatePropertyStatus
    @PropertyID INT,
    @NewStatus NVARCHAR(30)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Properties
            WHERE PropertyID = @PropertyID
        )
            THROW 50002, 'Property does not exist.', 1;

        UPDATE dbo.Properties
        SET Status = @NewStatus
        WHERE PropertyID = @PropertyID;

        SELECT
            'Property status updated successfully.' AS Message;
    END TRY

    BEGIN CATCH
        THROW;
    END CATCH
END;
GO


--Procedure 3: Register a Client
USE GreenAcresEMS;
GO

CREATE OR ALTER PROCEDURE dbo.usp_UpdatePropertyStatus
    @PropertyID INT,
    @NewStatus NVARCHAR(30)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Properties
            WHERE PropertyID = @PropertyID
        )
            THROW 50002, 'Property does not exist.', 1;

        UPDATE dbo.Properties
        SET Status = @NewStatus
        WHERE PropertyID = @PropertyID;

        SELECT 'Property status updated successfully.' AS Message;
    END TRY

    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

--Procedure 4 :Create A transaction
CREATE PROCEDURE dbo.usp_CreateTransaction
    @PropertyID INT,
    @ClientID INT,
    @AgentID INT,
    @TransactionType NVARCHAR(20),
    @Amount DECIMAL(18,2)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Properties
            WHERE PropertyID = @PropertyID
        )
            THROW 50005, 'Property does not exist.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Clients
            WHERE ClientID = @ClientID
              AND ClientStatus = 'Active'
        )
            THROW 50006, 'Active client does not exist.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Agents
            WHERE AgentID = @AgentID
              AND AgentStatus = 'Active'
        )
            THROW 50007, 'Active agent does not exist.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Properties
            WHERE PropertyID = @PropertyID
              AND Status IN ('Available', 'Reserved')
        )
            THROW 50008, 'Property is not available for transaction.', 1;

        IF @Amount <= 0
            THROW 50009, 'Transaction amount must be greater than zero.', 1;

        INSERT INTO dbo.Transactions
        (
            PropertyID,
            ClientID,
            AgentID,
            TransactionType,
            Amount,
            TransactionStatus
        )
        VALUES
        (
            @PropertyID,
            @ClientID,
            @AgentID,
            @TransactionType,
            @Amount,
            'Completed'
        );

        UPDATE dbo.Properties
        SET Status =
            CASE
                WHEN @TransactionType = 'Sale' THEN 'Sold'
                WHEN @TransactionType = 'Rent' THEN 'Rented'
            END
        WHERE PropertyID = @PropertyID;

        COMMIT TRANSACTION;

        SELECT
            'Transaction created successfully.' AS Message,
            SCOPE_IDENTITY() AS NewTransactionID;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

--Procedure 5: Create Maintenance Request
CREATE PROCEDURE dbo.usp_CreateMaintenanceRequest
    @PropertyID INT,
    @RequestDetails NVARCHAR(1000),
    @Priority NVARCHAR(20) = 'Medium'
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Properties
            WHERE PropertyID = @PropertyID
        )
            THROW 50010, 'Property does not exist.', 1;

        INSERT INTO dbo.MaintenanceRequests
        (
            PropertyID,
            RequestDetails,
            Priority,
            Status
        )
        VALUES
        (
            @PropertyID,
            @RequestDetails,
            @Priority,
            'Pending'
        );

        SELECT
            'Maintenance request created successfully.' AS Message,
            SCOPE_IDENTITY() AS NewRequestID;
    END TRY

    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

--Procedure 6 : Update Maintenance Status
CREATE PROCEDURE dbo.usp_UpdateMaintenanceStatus
    @RequestID INT,
    @NewStatus NVARCHAR(30)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.MaintenanceRequests
            WHERE RequestID = @RequestID
        )
            THROW 50011, 'Maintenance request does not exist.', 1;

        UPDATE dbo.MaintenanceRequests
        SET Status = @NewStatus
        WHERE RequestID = @RequestID;

        SELECT
            'Maintenance status updated successfully.' AS Message;
    END TRY

    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

--Operation History Triggers
--Trigger 1: Record Maintenance Status History
CREATE OR ALTER PROCEDURE dbo.usp_UpdateMaintenanceStatus
    @RequestID INT,
    @NewStatus NVARCHAR(30)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.MaintenanceRequests
            WHERE RequestID = @RequestID
        )
            THROW 50011, 'Maintenance request does not exist.', 1;

        UPDATE dbo.MaintenanceRequests
        SET Status = @NewStatus
        WHERE RequestID = @RequestID;

        SELECT
            'Maintenance status updated successfully.' AS Message;
    END TRY

    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

--Trigger 2 : Record Transaction History
CREATE TRIGGER dbo.trg_Transactions_History
ON dbo.Transactions
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.TransactionHistory
    (
        TransactionID,
        ActionType,
        ActionBy,
        Notes
    )
    SELECT
        I.TransactionID,

        CASE
            WHEN D.TransactionID IS NULL
                THEN 'CREATED'

            WHEN I.TransactionStatus = 'Cancelled'
                 AND ISNULL(D.TransactionStatus, '') <> 'Cancelled'
                THEN 'CANCELLED'

            ELSE 'UPDATED'
        END,

        SUSER_SNAME(),

        CASE
            WHEN D.TransactionID IS NULL
                THEN 'Transaction record created.'

            WHEN I.TransactionStatus = 'Cancelled'
                 AND ISNULL(D.TransactionStatus, '') <> 'Cancelled'
                THEN 'Transaction cancelled.'

            ELSE 'Transaction record updated.'
        END

    FROM inserted AS I
    LEFT JOIN deleted AS D
        ON I.TransactionID = D.TransactionID;
END;
GO

--Create Database Roles and Test users
CREATE ROLE role_PropertyManagementDeveloper;
GO

CREATE ROLE role_ClientPortalDeveloper;
GO

CREATE ROLE role_AnalyticsDeveloper;
GO

CREATE ROLE role_Auditor;
GO

CREATE ROLE role_DBA;
GO

--Create Test Users WITHOUT login
CREATE USER usr_propertydev WITHOUT LOGIN;
GO

CREATE USER usr_clientportal WITHOUT LOGIN;
GO

CREATE USER usr_analytics WITHOUT LOGIN;
GO

CREATE USER usr_auditor WITHOUT LOGIN;
GO

CREATE USER usr_dba WITHOUT LOGIN;
GO

--Assign Users to roles
ALTER ROLE role_PropertyManagementDeveloper
ADD MEMBER usr_propertydev;
GO

ALTER ROLE role_ClientPortalDeveloper
ADD MEMBER usr_clientportal;
GO

ALTER ROLE role_AnalyticsDeveloper
ADD MEMBER usr_analytics;
GO

ALTER ROLE role_Auditor
ADD MEMBER usr_auditor;
GO

ALTER ROLE role_DBA
ADD MEMBER usr_dba;
GO

--Apply GRANT, DENY and REVOKE Permission
--Property Management Development permissions
GRANT SELECT
ON dbo.vw_AvailableProperties
TO role_PropertyManagementDeveloper;
GO

GRANT SELECT
ON dbo.vw_MaintenanceOverview
TO role_PropertyManagementDeveloper;
GO

GRANT EXECUTE
ON dbo.usp_AddProperty
TO role_PropertyManagementDeveloper;
GO

GRANT EXECUTE
ON dbo.usp_UpdatePropertyStatus
TO role_PropertyManagementDeveloper;
GO

GRANT EXECUTE
ON dbo.usp_CreateMaintenanceRequest
TO role_PropertyManagementDeveloper;
GO

GRANT EXECUTE
ON dbo.usp_UpdateMaintenanceStatus
TO role_PropertyManagementDeveloper;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.Clients
TO role_PropertyManagementDeveloper;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.SystemUsers
TO role_PropertyManagementDeveloper;
GO

--Client portal developer permissions
GRANT SELECT
ON dbo.vw_AvailableProperties
TO role_ClientPortalDeveloper;
GO

GRANT SELECT
ON dbo.vw_MaskedClientDetails
TO role_ClientPortalDeveloper;
GO

GRANT EXECUTE
ON dbo.usp_RegisterClient
TO role_ClientPortalDeveloper;
GO

GRANT EXECUTE
ON dbo.usp_CreateTransaction
TO role_ClientPortalDeveloper;
GO

GRANT EXECUTE
ON dbo.usp_CreateMaintenanceRequest
TO role_ClientPortalDeveloper;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.Clients
TO role_ClientPortalDeveloper;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.SystemUsers
TO role_ClientPortalDeveloper;
GO

DENY SELECT
ON dbo.PropertyDocuments
TO role_ClientPortalDeveloper;
GO

--Analytics Developer Permissions
GRANT SELECT
ON dbo.vw_AnalyticsTransactionSummary
TO role_AnalyticsDeveloper;
GO

GRANT SELECT
ON dbo.vw_AvailableProperties
TO role_AnalyticsDeveloper;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.Clients
TO role_AnalyticsDeveloper;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.SystemUsers
TO role_AnalyticsDeveloper;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.PropertyDocuments
TO role_AnalyticsDeveloper;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.Transactions
TO role_AnalyticsDeveloper;
GO

--Auditor Permissions
GRANT SELECT
ON dbo.vw_AvailableProperties
TO role_Auditor;
GO

GRANT SELECT
ON dbo.vw_MaskedClientDetails
TO role_Auditor;
GO

GRANT SELECT
ON dbo.vw_AnalyticsTransactionSummary
TO role_Auditor;
GO

GRANT SELECT
ON dbo.vw_MaintenanceOverview
TO role_Auditor;
GO

GRANT SELECT
ON dbo.MaintenanceHistory
TO role_Auditor;
GO

GRANT SELECT
ON dbo.TransactionHistory
TO role_Auditor;
GO

DENY INSERT, UPDATE, DELETE
ON dbo.MaintenanceHistory
TO role_Auditor;
GO

DENY INSERT, UPDATE, DELETE
ON dbo.TransactionHistory
TO role_Auditor;
GO

DENY SELECT, INSERT, UPDATE, DELETE
ON dbo.SystemUsers
TO role_Auditor;
GO


--DBA Permission
GRANT CONTROL
ON DATABASE::GreenAcresEMS
TO role_DBA;
GO

--Revoke Demonstration
GRANT UPDATE
ON dbo.Clients
TO role_ClientPortalDeveloper;
GO

REVOKE UPDATE
ON dbo.Clients
FROM role_ClientPortalDeveloper;
GO

--Test Case 1 : Authorized Access Succeeds
EXECUTE AS USER = 'usr_propertydev';

SELECT *
FROM dbo.vw_AvailableProperties;

REVERT;
GO

--Test Case 2: Unauthorized Client Table Access is Denied
EXECUTE AS USER = 'usr_propertydev';

SELECT *
FROM dbo.Clients;

REVERT;
GO

--Test Case 3: Masked Client Information is Visible 
EXECUTE AS USER = 'usr_clientportal';

SELECT *
FROM dbo.vw_MaskedClientDetails;

REVERT;
GO

--Test Case 4: Direct Client Table Access is Denied
EXECUTE AS USER = 'usr_clientportal';

SELECT *
FROM dbo.Clients;

REVERT;
GO

--Test case 5: Analytics View access succeeds
EXECUTE AS USER = 'usr_analytics';

SELECT*
FROM dbo.vw_AnalyticsTransactionSummary;

REVERT;
GO

--Test Case 6: Analytics Developer Cannot View Raw Transaction
EXECUTE AS USER = 'usr_analytics';

SELECT*
FROM dbo.Transactions;

REVERT;
GO

--Test Case 7: Property Developer can use a stored procedure
EXECUTE AS USER = 'usr_propertydev';

EXEC dbo.usp_AddProperty
    @PropertyName = 'Cyber Heights Residence D-11',
    @PropertyType = 'Apartment',
    @Address = '11 Jalan Teknologi, Cyber Heights',
    @City = 'Cyberjaya',
    @State = 'Selangor',
    @Price = 475000.00,
    @Status = 'Available';

REVERT;
GO

--Test Case 8: Client Portal Developer Can Register a Client Through a Procedure
EXECUTE AS USER = 'usr_clientportal';

EXEC dbo.usp_RegisterClient
    @FullName = 'Farah Abdullah',
    @ContactNumber = '019-5551010',
    @Email = 'farah.abdullah@example.com',
    @Address = 'Cyberjaya, Selangor';

REVERT;
GO

--Test Case 9: Auditor has Read-only access
EXECUTE AS USER = 'usr_auditor';

SELECT*
FROM dbo.MaintenanceHistory;

REVERT;
GO
--Test Case 9: Unauthorized Modification
EXECUTE AS USER = 'usr_auditor';

DELETE FROM dbo.MaintenanceHistory;

REVERT;
GO

--Test Case 10: Maintenance Trigger Records Status Changes
EXEC dbo.usp_UpdateMaintenanceStatus
    @RequestID = 2,
    @NewStatus = 'In Progress';
GO

SELECT *
FROM dbo.MaintenanceHistory
WHERE RequestID = 2;
GO

/* View all tables */
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO


/* View all views */
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_NAME;
GO


/* View all stored procedures */
SELECT
    name AS ProcedureName
FROM sys.procedures
ORDER BY name;
GO


/* View database roles */
SELECT
    name AS RoleName
FROM sys.database_principals
WHERE type = 'R'
ORDER BY name;
GO


/* View role members */
SELECT
    R.name AS RoleName,
    U.name AS UserName
FROM sys.database_role_members AS RM
INNER JOIN sys.database_principals AS R
    ON RM.role_principal_id = R.principal_id
INNER JOIN sys.database_principals AS U
    ON RM.member_principal_id = U.principal_id
ORDER BY R.name, U.name;
GO

