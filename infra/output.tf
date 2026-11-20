# Declare output values for the main terraform module.
#
# This allows the main terraform module outputs to be referenced by other modules,
# or by the local machine as a way to reference created resources in Azure for local development.
# Secrets should not be added here.
#
# Outputs are automatically saved in the local azd environment .env file.
# To see these outputs, run `azd env get-values`. `azd env get-values --output json` for json output.

output "AZURE_LOCATION" {
  value = var.location
}

output "AZURE_TENANT_ID" {
  value = data.azurerm_client_config.current.tenant_id
}

output "AZURE_VNET_ID" {
  value = module.vnet.vnet_id
}

output "AZURE_PRIVATE_ENDPOINTS_SUBNET_ID" {
  value = module.vnet.private_endpoints_subnet_id
}

output "AZURE_COMPUTE_SUBNET_ID" {
  value = module.vnet.compute_subnet_id
}

output "AZURE_STORAGE_ACCOUNT_NAME" {
  value = { for name in local.azure_functions : name => module.storage[name].storage_account_name }
}

output "AZURE_STORAGE_ACCOUNT_ID" {
  value = { for name in local.azure_functions : name => module.storage[name].storage_account_id }
}

output "AZURE_STORAGE_PRIVATE_DNS_ZONE_IDS" {
  value = module.vnet.storage_private_dns_zone_ids
}

output "AZURE_STORAGE_PRIVATE_ENDPOINT_IDS" {
  value = { for name in local.azure_functions : name => module.storage[name].private_endpoint_ids }
}

output "AZURE_OUTBOUND_SUBNET_ID" {
  value = module.vnet.outbound_subnet_id
}

output "AZURE_USER_ASSIGNED_IDENTITY_ID" {
  value = module.uami.uami_id
}

output "AZURE_USER_ASSIGNED_IDENTITY_CLIENT_ID" {
  value = module.uami.uami_client_id
}

output "AZURE_USER_ASSIGNED_IDENTITY_NAME" {
  value = module.uami.uami_name
}

output "AZURE_LOG_ANALYTICS_WORKSPACE_ID" {
  value = module.loganalytics.id
}

output "AZURE_APPLICATION_INSIGHTS_ID" {
  value = module.app_insights.id
}

output "APPLICATIONINSIGHTS_CONNECTION_STRING" {
  value     = module.app_insights.connection_string
  sensitive = true
}

output "AZURE_SERVICE_PLAN_ID" {
  value = { for name in local.azure_functions : name => module.appserviceplan[name].id }
}

output "AZURE_FUNCTION_APP_ID" {
  value = { for name in local.azure_functions : name => module.functionapp[name].id }
}

output "AZURE_FUNCTION_APP_NAME" {
  value = { for name in local.azure_functions : name => module.functionapp[name].name }
}

output "AZURE_FUNCTION_APP_HOSTNAME" {
  value = { for name in local.azure_functions : name => module.functionapp[name].default_hostname }
}

output "AZURE_RESOURCE_GROUP" {
  value = azurerm_resource_group.rg.name
}

output "AZURE_APIM_NAME" {
  value = module.apim.api_management_name
}

output "AZURE_APIM_GATEWAY_URL" {
  value = module.apim.api_management_gateway_url
}

output "AZURE_SQL_SERVER_NAME" {
  value = module.sql.sql_server_name
}

output "AZURE_SQL_SERVER_FQDN" {
  value = module.sql.sql_server_fqdn
}

output "AZURE_SQL_DATABASE_NAME" {
  value = module.sql.database_name
}

output "AZURE_SERVICEBUS_FQDN" {
  value = module.servicebus.servicebus_fully_qualified_namespace
}

output "AZURE_SERVICEBUS_COMMANDS_QUEUE_NAME" {
  value = try(module.servicebus.servicebus_queues["commands"].name, null)
}

