output "diagnostic_setting_ids" {
  description = "Map of diagnostic target key to its diagnostic setting resource ID."
  value       = { for key, ds in azurerm_monitor_diagnostic_setting.this : key => ds.id }
}
