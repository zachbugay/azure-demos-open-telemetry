#!/usr/bin/env bash
#
# Usage:
#   ./scripts/run-data-generator.sh
#   USER_COUNT=250 ./scripts/run-data-generator.sh
set -euo pipefail

# Load azd environment variables from the current environment's .env file.
# https://learn.microsoft.com/azure/developer/azure-developer-cli/azd-extensibility#use-environment-variables-with-hooks
echo "Loading azd .env file from current environment"
while IFS='=' read -r key value; do
  value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e 's/\\"/"/g')
  export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

# User count precedence: CLI argument > USER_COUNT env var > default (100).
USER_COUNT="${1:-${USER_COUNT:-100}}"
if ! [[ "$USER_COUNT" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: user count must be a positive integer (got '$USER_COUNT')." >&2
  exit 1
fi

API_PATH="${APIM_API_PATH:-producer}"
APIM_BASE_URL="https://${AZURE_APIM_NAME}.azure-api.net/${API_PATH}"

# APIM subscription keys are secrets and are not stored in the azd .env, so fetch
# the built-in 'master' key unless one was supplied explicitly.
SUB_KEY="${APIM_SUBSCRIPTION_KEY:-}"
if [ -z "$SUB_KEY" ]; then
  echo "Fetching the built-in 'master' APIM subscription key..."
  SUB_KEY="$(az rest --method post \
    --uri "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${AZURE_APIM_NAME}/subscriptions/master/listSecrets?api-version=2022-08-01" \
    --query primaryKey -o tsv)"
fi

echo "APIM base URL     : $APIM_BASE_URL"
echo "Users to generate : $USER_COUNT"

dotnet run --project ./src/Bugay.Data.Generator/Bugay.Data.Generator.csproj -c Release \
  --ApimSubscriptionKey "$SUB_KEY" \
  --ApimBaseAddress "$APIM_BASE_URL"
