output "id" {
  description = "The resource ID of the Application Insights instance."
  value       = azurerm_application_insights.appi.id
}

output "name" {
  description = "The name of the Application Insights instance."
  value       = azurerm_application_insights.appi.name
}

output "connection_string" {
  description = "The Application Insights connection string."
  value       = azurerm_application_insights.appi.connection_string
  sensitive   = true
}
