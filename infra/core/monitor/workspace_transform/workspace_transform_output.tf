output "data_collection_rule_id" {
  description = "The resource ID of the workspace transformation Data Collection Rule (null if no transformations are defined)."
  value       = length(var.transformations) > 0 ? azurerm_monitor_data_collection_rule.transform[0].id : null
}
