locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = { azd-env-name : var.environment_name }
}

resource "azurerm_storage_account" "st" {
  name                     = substr(replace("st${local.environment}${local.workload}${var.resource_token}", "-", ""), 0, 24)
  location                 = var.location
  resource_group_name      = var.rg_name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  shared_access_key_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.authorized_ip_ranges
  }

  tags = merge(var.tags, {
    SecurityControl = "Ignore"
  })
}

resource "azurerm_private_endpoint" "st" {
  for_each            = var.storage_private_dns_zone_ids
  name                = "pe-${each.key}-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${each.key}-${azurerm_storage_account.st.name}"
    private_connection_resource_id = azurerm_storage_account.st.id
    subresource_names              = [each.key]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${each.key}-dns-zone-group"
    private_dns_zone_ids = [each.value]
  }

  tags = var.tags
}
