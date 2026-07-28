output "sql_server_id" {
  description = "The resource ID of the SQL Server."
  value       = azurerm_mssql_server.this.id
}

output "sql_server_name" {
  description = "The name of the SQL Server."
  value       = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL Server."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_id" {
  description = "The resource ID of the SQL Database."
  value       = azurerm_mssql_database.this.id
}

output "database_name" {
  description = "The name of the SQL Database."
  value       = azurerm_mssql_database.this.name
}

output "private_endpoint_id" {
  description = "The resource ID of the SQL Server private endpoint."
  value       = azurerm_private_endpoint.this.id
}
