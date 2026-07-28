output "storage_account_id" {
  description = "The resource ID of the storage account."
  value       = azurerm_storage_account.st.id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = azurerm_storage_account.st.name
}

output "storage_primary_blob_endpoint" {
  description = "The primary blob endpoint of the storage account."
  value       = azurerm_storage_account.st.primary_blob_endpoint
}

output "private_endpoint_ids" {
  description = "Map of storage sub-resource (blob, file, table, queue) to its private endpoint resource ID."
  value       = { for key, pe in azurerm_private_endpoint.st : key => pe.id }
}
