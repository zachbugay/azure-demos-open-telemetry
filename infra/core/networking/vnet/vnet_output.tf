output "vnet_id" {
  description = "The resource ID of the virtual network."
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the virtual network."
  value       = azurerm_virtual_network.vnet.name
}

output "private_endpoints_subnet_id" {
  description = "The resource ID of the private endpoints subnet."
  value       = azurerm_subnet.this["snet-private-endpoints"].id
}

output "compute_subnet_id" {
  description = "The resource ID of the compute subnet."
  value       = azurerm_subnet.this["snet-compute"].id
}

output "outbound_subnet_id" {
  description = "The resource ID of the outbound (regional VNet integration) subnet."
  value       = azurerm_subnet.this["snet-outbound"].id
}

output "apim_subnet_id" {
  description = "The resource ID of the API Management VNet integration subnet (delegated to Microsoft.Web/serverFarms)."
  value       = azurerm_subnet.this["snet-apim"].id
}

output "blob_private_dns_zone_id" {
  description = "The resource ID of the blob storage private DNS zone."
  value       = azurerm_private_dns_zone.storage["blob"].id
}

output "storage_private_dns_zone_ids" {
  description = "Map of storage sub-resource (blob, file, table, queue) to private DNS zone resource ID."
  value       = { for key, zone in azurerm_private_dns_zone.storage : key => zone.id }
}

output "sql_private_dns_zone_id" {
  description = "The resource ID of the Azure SQL (privatelink.database.windows.net) private DNS zone."
  value       = azurerm_private_dns_zone.sql.id
}
