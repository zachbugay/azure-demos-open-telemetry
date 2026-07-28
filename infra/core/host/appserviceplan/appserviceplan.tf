locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = { azd-env-name : var.environment_name }
}

resource "azurerm_service_plan" "asp" {
  name                = "asp-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = "Linux"
  sku_name            = var.sku == "flex_consumption" ? "FC1" : "EP1"

  tags = var.tags
}
