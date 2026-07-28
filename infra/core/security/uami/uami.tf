locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = { azd-env-name : var.environment_name }
}

resource "azurerm_user_assigned_identity" "uami" {
  name                = "id-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name

  tags = var.tags
}
