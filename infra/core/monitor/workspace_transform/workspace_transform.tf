locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = { azd-env-name : var.environment_name }
}

resource "azurerm_monitor_data_collection_rule" "transform" {
  count = length(var.transformations) > 0 ? 1 : 0

  name                = "dcr-transform-${local.name_suffix}"
  resource_group_name = var.rg_name
  location            = var.location
  kind                = "WorkspaceTransforms"

  destinations {
    log_analytics {
      name                  = "law-destination"
      workspace_resource_id = var.log_analytics_workspace_id
    }
  }

  dynamic "data_flow" {
    for_each = var.transformations
    content {
      streams       = ["Microsoft-Table-${data_flow.key}"]
      destinations  = ["law-destination"]
      transform_kql = data_flow.value
    }
  }

  tags = local.tags
}

resource "azurerm_monitor_data_collection_rule_association" "transform" {
  count = length(var.transformations) > 0 ? 1 : 0

  name                    = "workspace-transform"
  target_resource_id      = var.log_analytics_workspace_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.transform[0].id
  description             = "Applies ingestion-time transformations to the Log Analytics workspace."
}
