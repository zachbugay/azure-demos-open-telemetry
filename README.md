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

## Build

We are using the latest [Azure Functions Dotnet Worker](https://github.com/Azure/azure-functions-dotnet-worker).

```bash
dotnet build src/Bugay.Funcs.slnx
```

## Run locally with Docker Compose

The local stack runs the producer and consumer Functions, the Azure Service
Bus emulator, Azure SQL Edge as the Azure SQL-compatible local database, and
Azurite for the Functions host storage:

```bash
docker compose up --build
```

The Functions use Microsoft's .NET 11 Azure Functions image, which includes
the host. These two services target `linux/amd64` and use emulation on ARM64 hosts.

The producer is available at `http://localhost:7071`. The one-shot database
migrator creates `BugayDemo` and applies the schema before the consumer starts.
`MSSQL_SA_PASSWORD` can override the local-only default password. By running
the Service Bus emulator, you accept its Microsoft Software License Terms and
the SQL Server Linux license terms.

Run the data generator as a one-shot container against the local producer:

```bash
docker compose run --build --rm data-generator
```

This starts any required services, waits for the producer to be ready, generates
10 users with accounts and transactions, and exits. The generator is opt-in and
does not run with a normal `docker compose up`. To generate a different count:

```bash
docker compose run --build --rm -e GeneratorUserCount=25 data-generator
```

The local generator uses `ProducerBaseAddress=http://producer/api/`, so it needs
neither an API Management subscription key nor Azure credentials. Existing
`ApimBaseAddress` configuration still targets API Management. Azure Monitor
export is enabled when `APPLICATIONINSIGHTS_CONNECTION_STRING` is configured.

### View local telemetry in Seq

Compose also starts Seq at `http://localhost:8081`. Authentication is disabled
for this local demo. By running Seq, you accept the Seq End User License Agreement.
Telemetry is persisted in the `seq-data` volume.

The generator and both Functions export telemetry to Seq using OpenTelemetry.
Run the generator, then open Seq to search events and view traces. Open a span's
trace view to follow related operations across services, including SQL calls.

Inside Compose, the exporter uses `http://seq:5341/ingest/otlp` with the
`http/protobuf` protocol. For applications running directly on Windows, use
`OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:8081/ingest/otlp` and
`OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf` instead. Set `OTEL_SERVICE_NAME` to
the application name.

OTLP export is enabled only when `OTEL_EXPORTER_OTLP_ENDPOINT` is configured.
The existing Azure Monitor configuration remains available independently.

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
