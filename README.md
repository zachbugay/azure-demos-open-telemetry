# Azure Demos

An `azd` + Terraform template with two .NET 10 isolated Azure Functions and a database-first data layer.

### Data model

- `Users` (Id GUID PK, FirstName, LastName, CreatedAtUtc)
- `Accounts` (Id GUID PK, UserId FK -> Users, Name, CreatedAtUtc) — a user has many accounts
- `Transactions` (Id GUID PK, AccountId FK -> Accounts, Amount decimal(19,4) signed, CreatedAtUtc)
  - positive decimal `Accounts.Amount` increments, negative values decrement.

## Deploy

```bash
az login --tenant <your tenant>
azd auth login --tenant-id <your tenant>
azd up
```

This creates the Azure Service Bus Namespace, `sbq-commands` queue, the Azure SQL server/database (Entra-only auth),
and both function apps wired with:

- `ServiceBusConnection__fullyQualifiedNamespace`
- `ServiceBusCommandsQueueName`
- `SqlConnectionString`).

The `grant-uami` post-provision hook makes the user defined managed identity (uami) function's identity `db_owner`.

## Build

```bash
dotnet build src/Bugay.Funcs.slnx
```

## Create the database schema (DbUp)

The SQL server is Entra-only, so sign in first (`az login`) with database access.

```bash
SQL_FQDN=$(azd env get-value AZURE_SQL_SERVER_FQDN)
SQL_DB=$(azd env get-value AZURE_SQL_DATABASE_NAME)

dotnet run --project src/Bugay.Database -- "Server=tcp:${SQL_FQDN},1433;Database=${SQL_DB};Encrypt=True;TrustServerCertificate=False;"
```

## Reverse-engineer the entities (database-first)

Find documentation about (Reverse-engineering/Scaffolding entities here.)[https://learn.microsoft.com/en-us/ef/core/managing-schemas/scaffolding/?tabs=dotnet-core-cli]

```bash
cd ./src/Bugay.Data/
SQL_FQDN=$(azd env get-value AZURE_SQL_SERVER_FQDN)
SQL_DB=$(azd env get-value AZURE_SQL_DATABASE_NAME)

dotnet ef dbcontext scaffold \
  "Server=tcp:${SQL_FQDN},1433;Database=${SQL_DB};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=false;" \
  Microsoft.EntityFrameworkCore.SqlServer \
  --context AppDbContext \
  --context-namespace Bugay.Data \
  --namespace Bugay.Data.Entities \
  --output-dir Entities \
  --data-annotations \
  --no-onconfiguring \
  --force
```

The scripts are idempotent and DbUp within the Bugay.Database/Bugay.Database.csproj journals what's been run.
Re-running Bugay.Dataabse project is safe.
