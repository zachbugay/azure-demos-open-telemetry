# Azure Demos

An `azd` + Terraform template with two .NET 11 isolated Azure Functions and a database-first data layer.

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
- `SqlConnectionString`.

The `grant-uami` post-provision hook makes the user defined managed identity (uami) function's identity `db_owner`.

## Build and Run

We use docker, and docker compose to run all the required services.  waits for the producer to be ready, generates

10 users with accounts and transactions, and exits. The generator is opt-in and does not run with a normal `docker compose up`. To generate a different count:

```bash
docker compose up --build
```

Run the data generator:

```bash
docker compose run --build --rm data-generator # Generates 10 by default.
docker compose run --build --rm -e GeneratorUserCount=25 data-generator # Use the Environment variable to increase number of records. 
```

## SQL Server

You can connect to the SQL database locally using the following connection string:

`Data Source=127.0.0.1,1433;Initial Catalog=master;User ID=sa;Password=LocalSql!Passw0rd123;Pooling=False;Connect Timeout=30;Encrypt=False;Trust Server Certificate=True;Authentication=SqlPassword;Application Name=vscode-mssql;Command Timeout=5`

## Create the database schema (DbUp)

The SQL server is Entra-only, so sign in first (`az login`) with database access.

```bash
SQL_FQDN=$(azd env get-value AZURE_SQL_SERVER_FQDN)
SQL_DB=$(azd env get-value AZURE_SQL_DATABASE_NAME)

dotnet run --project src/Bugay.Database -- "Server=tcp:${SQL_FQDN},1433;Database=${SQL_DB};Encrypt=True;TrustServerCertificate=False;"
```

## Reverse-engineer the entities (database-first)

Find documentation about [Reverse-engineering/Scaffolding entities here.](https://learn.microsoft.com/en-us/ef/core/managing-schemas/scaffolding/?tabs=dotnet-core-cli)

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

## Run Generator Locally

```bash
docker compose run --build --rm -e GeneratorUserCount=25 data-generator
```
