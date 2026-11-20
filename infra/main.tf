locals {
  workload       = var.workload_name
  environment    = var.environment_name
  instance       = "001"
  sha            = base64encode(sha256("${var.environment_name}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_token = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
  name_suffix    = "${local.environment}-${local.workload}-${local.resource_token}-${local.instance}"

  azure_functions = ["consumer", "producer"]

  tags = { azd-env-name : var.environment_name }

  vnet_subnets = {
    "snet-private-endpoints" = {
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 8, 1)]
      delegation       = null
    }
    "snet-compute" = {
      address_prefixes  = [cidrsubnet(var.vnet_address_space[0], 8, 2)]
      service_endpoints = ["Microsoft.Sql"]
      delegation        = null
    }
    "snet-outbound" = {
      address_prefixes  = [cidrsubnet(var.vnet_address_space[0], 8, 3)]
      service_endpoints = ["Microsoft.Sql"]
      delegation = var.function_app_sku == "flex_consumption" ? {
        name         = "container-app-environments-delegation"
        service_name = "Microsoft.App/environments"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        } : {
        name         = "serverfarms-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-apim" = {
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 8, 4)]
      delegation = {
        name         = "apim-serverfarms-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
      security_rules = [
        {
          name                       = "AllowStorageOutbound"
          priority                   = 100
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "Storage"
        },
        {
          name                       = "AllowKeyVaultOutbound"
          priority                   = 110
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "AzureKeyVault"
        },
      ]
    }
  }
}

data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = { azd-env-name : var.environment_name }
}

module "vnet" {
  source           = "./core/networking/vnet"
  location         = var.location
  environment_name = var.environment_name
  address_space    = var.vnet_address_space
  subnets          = local.vnet_subnets
  workload_name    = local.workload
  rg_name          = azurerm_resource_group.rg.name
  resource_token   = local.resource_token
  tags             = local.tags
}

module "storage" {
  for_each                     = toset(local.azure_functions)
  source                       = "./core/storage/storageaccount"
  location                     = var.location
  environment_name             = var.environment_name
  workload_name                = "${each.value}${local.workload}"
  rg_name                      = azurerm_resource_group.rg.name
  resource_token               = local.resource_token
  tags                         = local.tags
  private_endpoint_subnet_id   = module.vnet.private_endpoints_subnet_id
  storage_private_dns_zone_ids = module.vnet.storage_private_dns_zone_ids
  authorized_ip_ranges         = distinct(concat([chomp(data.http.current_ip.response_body)], var.authorized_ip_ranges))
}

module "loganalytics" {
  source           = "./core/monitor/loganalytics"
  location         = var.location
  environment_name = var.environment_name
  workload_name    = local.workload
  rg_name          = azurerm_resource_group.rg.name
  resource_token   = local.resource_token
  tags             = local.tags
}

module "app_insights" {
  source                     = "./core/monitor/application_insights"
  location                   = var.location
  environment_name           = var.environment_name
  workload_name              = local.workload
  rg_name                    = azurerm_resource_group.rg.name
  resource_token             = local.resource_token
  tags                       = local.tags
  log_analytics_workspace_id = module.loganalytics.id
}

module "uami" {
  source           = "./core/security/uami"
  location         = var.location
  environment_name = var.environment_name
  workload_name    = local.workload
  rg_name          = azurerm_resource_group.rg.name
  resource_token   = local.resource_token
  tags             = local.tags
}

module "role_assignments" {
  source = "./core/security/role_assignments"
  role_assignments = merge(
    {
      for name in local.azure_functions : "storage_data_${name}" => {
        scope = module.storage[name].storage_account_id
        principal_ids = [
          data.azurerm_client_config.current.object_id,
          module.uami.uami_principal_id,
        ]
        role_definition_names = [
          "Storage Blob Data Owner",
          "Storage Account Contributor",
          "Storage File Data SMB Share Contributor",
          "Storage Table Data Contributor",
          "Storage Queue Data Contributor",
        ]
      }
    },
    {
      application_insights = {
        scope = module.app_insights.id
        principal_ids = [
          data.azurerm_client_config.current.object_id,
          module.uami.uami_principal_id,
        ]
        role_definition_names = ["Monitoring Metrics Publisher"]
      }
      log_analytics = {
        scope                 = module.loganalytics.id
        principal_ids         = [module.uami.uami_principal_id]
        role_definition_names = ["Monitoring Contributor"]
      }
      azure_service_bus_workload = {
        scope         = module.servicebus.servicebus_namespace_id
        principal_ids = [module.uami.uami_principal_id]
        role_definition_names = [
          "Azure Service Bus Data Receiver",
          "Azure Service Bus Data Sender",
        ]
      }
      azure_service_bus_workload_User = {
        scope                 = module.servicebus.servicebus_namespace_id
        principal_ids         = [data.azurerm_client_config.current.object_id]
        role_definition_names = ["Azure Service Bus Data Owner"]
      }
    }
  )
}

module "diagnostics" {
  source                     = "./core/monitor/diagnostics"
  log_analytics_workspace_id = module.loganalytics.id

  diagnostic_targets = merge(
    {
      vnet = {
        resource_id       = module.vnet.vnet_id
        metric_categories = ["AllMetrics"]
      }
    },
    {
      for name in local.azure_functions : "functionapp_${name}" => {
        resource_id        = module.functionapp[name].id
        log_category_group = "allLogs"
        metric_categories  = ["AllMetrics"]
      }
    },
    {
      for name in local.azure_functions : "storage_${name}" => {
        resource_id       = module.storage[name].storage_account_id
        metric_categories = ["Transaction"]
      }
    },
    merge([
      for name in local.azure_functions : {
        for service in ["blob", "file", "queue", "table"] : "storage_${name}_${service}" => {
          resource_id        = "${module.storage[name].storage_account_id}/${service}Services/default"
          log_category_group = "allLogs"
          metric_categories  = ["Transaction"]
        }
      }
    ]...)
  )
}

module "workspace_transform" {
  source                     = "./core/monitor/workspace_transform"
  location                   = var.location
  environment_name           = var.environment_name
  workload_name              = local.workload
  rg_name                    = azurerm_resource_group.rg.name
  resource_token             = local.resource_token
  log_analytics_workspace_id = module.loganalytics.id
}

module "appserviceplan" {
  for_each         = toset(local.azure_functions)
  source           = "./core/host/appserviceplan"
  location         = var.location
  environment_name = var.environment_name
  sku              = var.function_app_sku
  workload_name    = "${each.value}${local.workload}"
  rg_name          = azurerm_resource_group.rg.name
  resource_token   = local.resource_token
  tags             = local.tags
}

# run az functionapp list-runtimes to get the most up-to-date list of supported versions
module "functionapp" {
  for_each                               = toset(local.azure_functions)
  source                                 = "./core/host/functionapp"
  location                               = var.location
  environment_name                       = var.environment_name
  sku                                    = var.function_app_sku
  workload_name                          = "${each.value}-${local.workload}"
  rg_name                                = azurerm_resource_group.rg.name
  resource_token                         = local.resource_token
  tags                                   = local.tags
  service_plan_id                        = module.appserviceplan[each.key].id
  storage_account_id                     = module.storage[each.key].storage_account_id
  storage_account_name                   = module.storage[each.key].storage_account_name
  storage_primary_blob_endpoint          = module.storage[each.key].storage_primary_blob_endpoint
  outbound_subnet_id                     = module.vnet.outbound_subnet_id
  uami_id                                = module.uami.uami_id
  uami_client_id                         = module.uami.uami_client_id
  uami_tenant_id                         = data.azurerm_client_config.current.tenant_id
  runtime_name                           = "dotnet-isolated"
  runtime_version                        = "10.0"
  application_insights_connection_string = module.app_insights.connection_string
  service_name                           = each.value

  extra_app_settings = {
    "ServiceBusConnection__fullyQualifiedNamespace" = "${module.servicebus.servicebus_namespace_name}.servicebus.windows.net"
    "ServiceBusConnection__credential"              = "managedidentity"
    "ServiceBusConnection__clientId"                = module.uami.uami_client_id
    "ServiceBusCommandsQueueName"                   = module.servicebus.servicebus_queues["commands"].name
    "SqlConnectionString"                           = "Server=tcp:${module.sql.sql_server_fqdn},1433;Database=${module.sql.database_name};Authentication=Active Directory Managed Identity;User Id=${module.uami.uami_client_id};Encrypt=True;TrustServerCertificate=False;"
  }

  depends_on = [
    module.storage,
    module.role_assignments
  ]
}

module "servicebus" {
  source           = "./core/messaging/servicebus"
  location         = var.location
  environment_name = var.environment_name
  sku              = var.service_bus_sku
  workload_name    = local.workload
  rg_name          = azurerm_resource_group.rg.name
  resource_token   = local.resource_token
  tags             = local.tags
  topics = {
    topic_1 = {
      name                 = "topic-1"
      partitioning_enabled = true
    }
  }
  queues = {
    commands = {
      name                 = "commands"
      partitioning_enabled = false
    }
  }
}

module "sql" {
  source           = "./core/database/mssql"
  location         = var.location
  environment_name = var.environment_name
  workload_name    = local.workload
  rg_name          = azurerm_resource_group.rg.name
  resource_token   = local.resource_token
  tags             = local.tags

  entra_administrator_login     = data.azurerm_client_config.current.object_id
  entra_administrator_object_id = data.azurerm_client_config.current.object_id
  entra_administrator_tenant_id = data.azurerm_client_config.current.tenant_id

  private_endpoint_subnet_id = module.vnet.private_endpoints_subnet_id
  sql_private_dns_zone_id    = module.vnet.sql_private_dns_zone_id
  authorized_ip_addresses    = distinct(concat([chomp(data.http.current_ip.response_body)], var.authorized_ip_ranges))
}

module "apim" {
  source               = "./core/gateway/apim"
  location             = var.location
  environment_name     = var.environment_name
  sku_name             = var.apim_sku_name
  sku_count            = var.apim_sku_count
  workload_name        = local.workload
  rg_name              = azurerm_resource_group.rg.name
  resource_token       = local.resource_token
  tags                 = local.tags
  publisher_email      = var.apim_publisher_email
  publisher_name       = var.apim_publisher_name
  subnet_id            = module.vnet.apim_subnet_id
  virtual_network_type = "External"

  application_insights_enabled = true
  application_insights_id      = module.app_insights.id
  application_insights_name    = module.app_insights.name

  uami_id        = module.uami.uami_id
  uami_client_id = module.uami.uami_client_id

  depends_on = [module.vnet, module.role_assignments]
}
