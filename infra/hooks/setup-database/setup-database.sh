#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IFS=$'\n\t'

required_vars=(
  AZURE_SQL_SERVER_FQDN
  AZURE_SQL_DATABASE_NAME
  AZURE_USER_ASSIGNED_IDENTITY_NAME
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: $var is not set. Run 'azd provision' first." >&2
    exit 1
  fi
done

if ! command -v sqlcmd >/dev/null 2>&1; then
  echo "ERROR: 'sqlcmd' (go-sqlcmd) is not installed or not on PATH." >&2
  echo "Install instructions: https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility" >&2
  exit 1
fi

echo "Granting '${AZURE_USER_ASSIGNED_IDENTITY_NAME}' db_owner on database '${AZURE_SQL_DATABASE_NAME}'..."

sqlcmd \
  -S "${AZURE_SQL_SERVER_FQDN}" \
  -d "${AZURE_SQL_DATABASE_NAME}" \
  --authentication-method=ActiveDirectoryAzCli \
  -C -b \
  -v UamiName="${AZURE_USER_ASSIGNED_IDENTITY_NAME}" \
  -i "${script_dir}/grant-uami.sql"

echo "Successfully granted database access to '${AZURE_USER_ASSIGNED_IDENTITY_NAME}'."

echo "Executing DbUp ..."

# https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication/credential-chains?tabs=dac#exclude-a-credential-type-category
# This hook runs on the developer machine during 'azd provision', so DefaultAzureCredential
# must use developer credentials (Azure CLI). Without this, ManagedIdentityCredential's IMDS
# probe times out and fails the chain. AZURE_TOKEN_CREDENTIALS=dev excludes managed identity.
AZURE_TOKEN_CREDENTIALS=dev dotnet run --project src/Bugay.Database -- \
  --DATABASE_CONNECTION_STRING "Server=tcp:${AZURE_SQL_SERVER_FQDN},1433;Database=${AZURE_SQL_DATABASE_NAME};Encrypt=True;TrustServerCertificate=True;"

echo "DbUp completed! Reverse-engineering entities into src/Bugay.Data ..."

if ! dotnet ef --version >/dev/null 2>&1; then
  echo "ERROR: 'dotnet ef' tool is not installed." >&2
  echo "Install it with: dotnet tool install --global dotnet-ef" >&2
  exit 1
fi

# https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication/credential-chains?tabs=dac#exclude-a-credential-type-category
# Using AZURE_TOKEN_CREDENTIALS=dev to exclude credential type categories.
AZURE_TOKEN_CREDENTIALS=dev dotnet ef dbcontext scaffold \
  "Server=tcp:${AZURE_SQL_SERVER_FQDN},1433;Database=${AZURE_SQL_DATABASE_NAME};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;" \
  Microsoft.EntityFrameworkCore.SqlServer \
  --project src/Bugay.Data \
  --startup-project src/Bugay.Data \
  --context AppDbContext \
  --context-namespace Bugay.Data \
  --namespace Bugay.Data.Entities \
  --output-dir Entities \
  --data-annotations \
  --no-onconfiguring \
  --force

echo "Database setup complete: UAMI granted, migrations applied, entities scaffolded!"
