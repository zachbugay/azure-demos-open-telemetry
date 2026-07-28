locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"
  storage_private_dns_zones = {
    blob  = "privatelink.blob.core.windows.net"
    file  = "privatelink.file.core.windows.net"
    table = "privatelink.table.core.windows.net"
    queue = "privatelink.queue.core.windows.net"
  }

  tags = { azd-env-name : var.environment_name }

  subnets_with_nsg = { for name, config in var.subnets : name => config if config.security_rules != null }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = var.address_space

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = local.subnets_with_nsg

  name                = "nsg-${each.key}-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnets_with_nsg

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

resource "azurerm_private_dns_zone" "storage" {
  for_each            = local.storage_private_dns_zones
  name                = each.value
  resource_group_name = var.rg_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  for_each              = local.storage_private_dns_zones
  name                  = "${azurerm_virtual_network.vnet.name}-${each.key}-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.storage[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.rg_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "${azurerm_virtual_network.vnet.name}-sql-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = var.tags
}
