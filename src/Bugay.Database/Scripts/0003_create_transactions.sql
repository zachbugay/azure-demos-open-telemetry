-- 0003: Transactions table (tied to an Account)
-- Amount is a signed decimal: positive = increment, negative = decrement.
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Transactions' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.Transactions
    (
        Id           UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Transactions PRIMARY KEY,
        AccountId    UNIQUEIDENTIFIER NOT NULL,
        Amount       DECIMAL(19, 4)   NOT NULL,
        CreatedAtUtc DATETIME2(3)     NOT NULL CONSTRAINT DF_Transactions_CreatedAtUtc DEFAULT (SYSUTCDATETIME())
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Transactions_Accounts_AccountId')
BEGIN
    ALTER TABLE dbo.Transactions
        ADD CONSTRAINT FK_Transactions_Accounts_AccountId
        FOREIGN KEY (AccountId) REFERENCES dbo.Accounts (Id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Transactions_AccountId' AND object_id = OBJECT_ID(N'dbo.Transactions'))
BEGIN
    CREATE INDEX IX_Transactions_AccountId ON dbo.Transactions (AccountId);
END;
GO
