output "api_management_id" {
  description = "The resource ID of the API Management instance."
  value       = azurerm_api_management.apim.id
}

output "api_management_name" {
  description = "The name of the API Management instance."
  value       = azurerm_api_management.apim.name
}

output "api_management_gateway_url" {
  description = "The gateway URL of the API Management instance."
  value       = azurerm_api_management.apim.gateway_url
}
