locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  tags = merge(var.tags, { azd-env-name : var.environment_name, SecurityControl : "Ignore" })
}

resource "azurerm_mssql_server" "this" {
  name                = "sql-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  version             = "12.0"
  minimum_tls_version = "1.2"

  public_network_access_enabled = true

  azuread_administrator {
    login_username              = var.entra_administrator_login
    object_id                   = var.entra_administrator_object_id
    tenant_id                   = var.entra_administrator_tenant_id
    azuread_authentication_only = true
  }

  tags = local.tags
}

resource "azurerm_mssql_database" "this" {
  name        = "sqldb-${local.name_suffix}"
  server_id   = azurerm_mssql_server.this.id
  collation   = var.collation
  sku_name    = var.database_sku_name
  max_size_gb = var.database_max_size_gb

  tags = local.tags
}

resource "azurerm_mssql_firewall_rule" "authorized" {
  for_each         = toset(var.authorized_ip_addresses)
  name             = "AllowIp-${replace(each.value, ".", "-")}"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

resource "azurerm_mssql_virtual_network_rule" "authorized" {
  for_each  = toset(var.authorized_subnet_ids)
  name      = "AllowSubnet-${replace(reverse(split("/", each.value))[0], "_", "-")}"
  server_id = azurerm_mssql_server.this.id
  subnet_id = each.value
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-sql-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-sql-${azurerm_mssql_server.this.name}"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [var.sql_private_dns_zone_id]
  }

  tags = local.tags
}
