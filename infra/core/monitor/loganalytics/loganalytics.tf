locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = { azd-env-name : var.environment_name }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}
