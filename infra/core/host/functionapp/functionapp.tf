locals {
  workload    = var.workload_name
  environment = var.environment_name
  instance    = "001"
  name_suffix = "${local.environment}-${local.workload}-${var.resource_token}-${local.instance}"

  base_app_settings = {
    # Identity-based connection details for the AzureWebJobsStorage host storage.
    # https://learn.microsoft.com/en-us/azure/durable-task/durable-functions/durable-functions-configure-managed-identity#identity-based-connections-for-app-deployed-to-azure
    # azure_rm will create a non-empty `AzureWebJobsStorage` which messes up Managed Identity connection to the storage account.
    # azure_rm will also create a non-empty `DEPLOYMENT_STORAGE_CONNECTION_STRING`, which doesn't appear to have any effect.
    # Set as an empty string until that is fixed. 
    "AzureWebJobsStorage"              = ""
    "AzureWebJobsStorage__accountName" = var.storage_account_name
    # These are required for User Assigned Managed Identities. Not required for System Assigned.
    # These are required if using a Durable Function. https:// protocol is required.
    "AzureWebJobsStorage__blobServiceUri"       = "https://${var.storage_account_name}.blob.core.windows.net"
    "AzureWebJobsStorage__queueServiceUri"      = "https://${var.storage_account_name}.queue.core.windows.net"
    "AzureWebJobsStorage__tableServiceUri"      = "https://${var.storage_account_name}.table.core.windows.net"
    "AzureWebJobsStorage__credential"           = "managedidentity"
    "AzureWebJobsStorage__clientId"             = var.uami_client_id
    "AZURE_CLIENT_ID"                           = var.uami_client_id
    "AZURE_TENANT_ID"                           = var.uami_tenant_id
    "APPLICATIONINSIGHTS_AUTHENTICATION_STRING" = "ClientId=${var.uami_client_id};Authorization=AAD"
    "AZURE_EXPERIMENTAL_ENABLE_ACTIVITY_SOURCE" = "true"
  }

  tags = { azd-env-name : var.environment_name }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app
resource "azurerm_linux_function_app" "func" {
  count = var.sku == "functions_premium" ? 1 : 0

  name                = "func-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = var.service_plan_id

  storage_account_name          = var.storage_account_name
  storage_uses_managed_identity = true

  public_network_access_enabled = true
  virtual_network_subnet_id     = var.outbound_subnet_id

  functions_extension_version = "~4"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.uami_id]
  }

  site_config {
    application_insights_connection_string = var.application_insights_connection_string
    vnet_route_all_enabled                 = true

    application_stack {
      python_version              = var.runtime_name == "python" ? var.runtime_version : null
      dotnet_version              = contains(["dotnet", "dotnet-isolated"], var.runtime_name) ? var.runtime_version : null
      use_dotnet_isolated_runtime = var.runtime_name == "dotnet-isolated" ? true : null
    }
  }

  app_settings = merge(local.base_app_settings, var.extra_app_settings, {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD"              = "true"
    "WEBSITE_RUN_FROM_PACKAGE"       = "1" # https://learn.microsoft.com/en-us/azure/azure-functions/run-functions-from-deployment-package
  })

  tags = merge(var.tags, { azd-service-name = var.service_name })

  lifecycle {
    # https://support.hashicorp.com/hc/en-us/articles/12696017185043-Terraform-continuously-detecting-changes-to-hidden-link-tags
    ignore_changes = [tags["hidden-link: /app-insights-resource-id"]]
  }
}

resource "azurerm_storage_container" "flex_deployment" {
  count = var.sku == "flex_consumption" ? 1 : 0

  name                  = "function-deployment"
  storage_account_id    = var.storage_account_id
  container_access_type = "private"
}

resource "azurerm_function_app_flex_consumption" "func" {
  count = var.sku == "flex_consumption" ? 1 : 0

  name                = "func-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = var.service_plan_id

  storage_container_type            = "blobContainer"
  storage_container_endpoint        = "${var.storage_primary_blob_endpoint}${azurerm_storage_container.flex_deployment[0].name}"
  storage_authentication_type       = "UserAssignedIdentity"
  storage_user_assigned_identity_id = var.uami_id

  runtime_name    = var.runtime_name
  runtime_version = var.runtime_version

  public_network_access_enabled = true
  virtual_network_subnet_id     = var.outbound_subnet_id

  app_settings = merge(local.base_app_settings, var.extra_app_settings, {})

  identity {
    type         = "UserAssigned"
    identity_ids = [var.uami_id]
  }

  site_config {
    application_insights_connection_string = var.application_insights_connection_string
    vnet_route_all_enabled                 = true
  }

  webdeploy_publish_basic_authentication_enabled = false # https://learn.microsoft.com/en-us/azure/app-service/configure-basic-auth-disable?tabs=cli

  tags = merge(var.tags, { azd-service-name = var.service_name })

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }
}
