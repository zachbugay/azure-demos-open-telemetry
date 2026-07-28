output "uami_id" {
  description = "The resource ID of the user assigned managed identity."
  value       = azurerm_user_assigned_identity.uami.id
}

output "uami_name" {
  description = "The name of the user assigned managed identity."
  value       = azurerm_user_assigned_identity.uami.name
}

output "uami_client_id" {
  description = "The client ID of the user assigned managed identity."
  value       = azurerm_user_assigned_identity.uami.client_id
}

output "uami_principal_id" {
  description = "The principal (object) ID of the user assigned managed identity."
  value       = azurerm_user_assigned_identity.uami.principal_id
}
