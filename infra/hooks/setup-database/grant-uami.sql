IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$(UamiName)')
    CREATE USER [$(UamiName)] FROM EXTERNAL PROVIDER;

IF IS_ROLEMEMBER('db_owner', N'$(UamiName)') = 0
    ALTER ROLE db_owner ADD MEMBER [$(UamiName)];
