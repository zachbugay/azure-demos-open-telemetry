output "id" {
  description = "The resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.law.id
}

output "name" {
  description = "The name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.law.name
}
