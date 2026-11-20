locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = { azd-env-name : var.environment_name }
}

resource "azurerm_application_insights" "appi" {
  name                         = "appi-${local.name_suffix}"
  location                     = var.location
  resource_group_name          = var.rg_name
  workspace_id                 = var.log_analytics_workspace_id
  application_type             = "web"
  local_authentication_enabled = false
  tags                         = var.tags
}
