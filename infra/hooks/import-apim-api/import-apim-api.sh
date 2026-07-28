#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

readonly API_ID="producer-api"
readonly API_PATH="producer"
readonly API_DISPLAY_NAME="ProducerAPI"
readonly FUNCTION_KEY="producer"

function check_required_tools {
  local -n _messages="$1"
  local -n _urls="$2"
  local tool

  echo "Checking if tools exist..."
  for tool in "${!_messages[@]}"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      echo "ERROR: '${tool}' ${_messages[${tool}]} (${_urls[${tool}]})" >&2
      exit 1
    fi
    echo "OK: '${tool}' found"
  done
  echo "Required tools exist!"
}

function check_required_terraform_outputs {
  local -n _required_outputs="$1"
  local name

  echo "Checking if required variables exist..."
  for name in "${_required_outputs[@]}"; do
    if [[ -z "${!name:-}" ]]; then
      echo "ERROR: ${name} is not set. Run 'azd provision' first." >&2
      exit 1
    fi
  done
  echo "Required values exist!"
}

function get_function_hostname {
  local key="$1"
  local azure_function_app_hostname="$2"
  local hostname

  if ! hostname="$(jq --exit-status --raw-output --arg key "${key}" '.[$key]' <<<"${azure_function_app_hostname}")"; then
    echo "ERROR: No hostname found for function '${key}'." >&2
    exit 1
  fi

  printf '%s' "${hostname}"
}

function main {
  local required_terraform_outputs=(
    AZURE_RESOURCE_GROUP
    AZURE_APIM_NAME
    AZURE_FUNCTION_APP_HOSTNAME
  )

  local -A messages url

  # Messages for required tools
  messages["az"]="(Azure CLI) is not installed."
  messages["jq"]="jq cli JSON processor is not installed."

  # Download urls for required tools
  url["az"]="https://learn.microsoft.com/cli/azure/install-azure-cli"
  url["jq"]="https://jqlang.github.io/jq/download/"

  check_required_tools messages url
  check_required_terraform_outputs required_terraform_outputs

  # Get Producer's Azure Function FQDN.
  local function_hostname
  function_hostname="$(get_function_hostname "${FUNCTION_KEY}" "${AZURE_FUNCTION_APP_HOSTNAME}")"

  local spec_url="https://${function_hostname}/api/openapi/v3.json"

  echo "Importing OpenAPI definition from '${spec_url}'"
  echo "  into APIM '${AZURE_APIM_NAME}' as api-id '${API_ID}' (path '/${API_PATH}')..."

  az apim api import \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --service-name "${AZURE_APIM_NAME}" \
    --api-id "${API_ID}" \
    --path "${API_PATH}" \
    --display-name "${API_DISPLAY_NAME}" \
    --service-url "https://${function_hostname}/api" \
    --specification-format OpenApi \
    --specification-url "${spec_url}"

  echo "Successfully imported API '${API_ID}' into '${AZURE_APIM_NAME}'."
}

main "$@"
