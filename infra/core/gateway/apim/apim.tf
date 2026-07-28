locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = { azd-env-name : var.environment_name }
}

# https://learn.microsoft.com/en-us/azure/api-management/quickstart-terraform?tabs=azure-cli
resource "azurerm_api_management" "apim" {
  name                = "apim-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "${var.sku_name}_${var.sku_count}"

  virtual_network_type = var.virtual_network_type

  dynamic "identity" {
    for_each = var.uami_id != null ? [var.uami_id] : []
    content {
      type         = "UserAssigned"
      identity_ids = [identity.value]
    }
  }

  dynamic "virtual_network_configuration" {
    for_each = var.subnet_id != null ? [var.subnet_id] : []
    content {
      subnet_id = virtual_network_configuration.value
    }
  }

  tags = var.tags
}

data "azurerm_application_insights" "appi" {
  count = var.application_insights_enabled ? 1 : 0

  name                = var.application_insights_name
  resource_group_name = var.rg_name
}

resource "azurerm_api_management_logger" "appinsights" {
  count = var.application_insights_enabled ? 1 : 0

  name                = "${data.azurerm_application_insights.appi[0].name}-logger"
  resource_group_name = var.rg_name
  resource_id         = data.azurerm_application_insights.appi[0].id
  api_management_name = azurerm_api_management.apim.name
  description         = "Observability with: ${data.azurerm_application_insights.appi[0].name} connected with UAMI: ${var.uami_client_id}."

  application_insights {
    connection_string  = data.azurerm_application_insights.appi[0].connection_string
    identity_client_id = var.uami_client_id
  }
}

resource "azurerm_api_management_diagnostic" "appinsights" {
  count = var.application_insights_enabled ? 1 : 0

  identifier               = "applicationinsights"
  resource_group_name      = var.rg_name
  api_management_name      = azurerm_api_management.apim.name
  api_management_logger_id = azurerm_api_management_logger.appinsights[0].id

  sampling_percentage       = 100.0 # All requests will be logged.
  http_correlation_protocol = "W3C"
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "verbose"
  operation_name_format     = "Url"

  frontend_request {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }

  backend_request {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  backend_response {
    body_bytes = 1024
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }

  lifecycle {
    replace_triggered_by = [azurerm_api_management_logger.appinsights[0].id]
  }
}

