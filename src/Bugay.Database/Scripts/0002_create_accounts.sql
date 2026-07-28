-- 0002: Accounts table (1:many -> Users)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Accounts' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.Accounts
    (
        Id           UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Accounts PRIMARY KEY,
        UserId       UNIQUEIDENTIFIER NOT NULL,
        Name         NVARCHAR(200)    NULL,
        CreatedAtUtc DATETIME2(3)     NOT NULL CONSTRAINT DF_Accounts_CreatedAtUtc DEFAULT (SYSUTCDATETIME())
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Accounts_Users_UserId')
BEGIN
    ALTER TABLE dbo.Accounts
        ADD CONSTRAINT FK_Accounts_Users_UserId
        FOREIGN KEY (UserId) REFERENCES dbo.Users (Id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Accounts_UserId' AND object_id = OBJECT_ID(N'dbo.Accounts'))
BEGIN
    CREATE INDEX IX_Accounts_UserId ON dbo.Accounts (UserId);
END;
GO
