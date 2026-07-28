output "id" {
  description = "The resource ID of the Azure Functions hosting plan."
  value       = azurerm_service_plan.asp.id
}

output "name" {
  description = "The name of the Azure Functions hosting plan."
  value       = azurerm_service_plan.asp.name
}
