-- 0001: Users table
-- Idempotent: safe to re-run. DbUp journals executed scripts, but the guards
-- below keep the script harmless even if applied manually.
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Users' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.Users
    (
        Id           UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
        FirstName    NVARCHAR(100)    NOT NULL,
        LastName     NVARCHAR(100)    NOT NULL,
        CreatedAtUtc DATETIME2(3)     NOT NULL CONSTRAINT DF_Users_CreatedAtUtc DEFAULT (SYSUTCDATETIME())
    );
END;
GO
