locals {

  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = { azd-env-name : var.environment_name }

  topics = var.topics
  queues = var.queues
}

resource "azurerm_servicebus_namespace" "sb" {
  name                = "sb-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = var.sku

  local_auth_enabled            = false
  public_network_access_enabled = true

  tags = var.tags
}

resource "azurerm_servicebus_topic" "this" {
  for_each             = local.topics
  namespace_id         = azurerm_servicebus_namespace.sb.id
  name                 = "sbt-${each.value.name}"
  partitioning_enabled = each.value.partitioning_enabled
}

resource "azurerm_servicebus_queue" "this" {
  for_each     = local.queues
  namespace_id = azurerm_servicebus_namespace.sb.id
  name         = "sbq-${each.value.name}"

}

