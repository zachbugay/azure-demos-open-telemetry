variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "environment_name" {
  description = "The name of the azd environment to be deployed"
  type        = string
}

variable "sku" {
  description = "The Azure Functions hosting plan to deploy."
  type        = string

  validation {
    condition     = contains(["flex_consumption", "functions_premium"], var.sku)
    error_message = "sku must be either \"flex_consumption\" or \"functions_premium\"."
  }
}

variable "workload_name" {
  description = "A name of a workload that identifies an instance of a Deployment Stamp."
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group to deploy resources into"
  type        = string
}

variable "tags" {
  description = "A list of tags used for deployed services."
  type        = map(string)
}

variable "resource_token" {
  description = "A suffix string to centrally mitigate resource name collisions."
  type        = string
}

variable "service_plan_id" {
  description = "The resource ID of the Azure Functions hosting plan."
  type        = string
}

variable "storage_account_id" {
  description = "The resource ID of the storage account used by the function app."
  type        = string
}

variable "storage_account_name" {
  description = "The name of the backend storage account used by the function app."
  type        = string
}

variable "storage_primary_blob_endpoint" {
  description = "The primary Blob service endpoint used for Flex Consumption deployment storage."
  type        = string
}

variable "outbound_subnet_id" {
  description = "The resource ID of the delegated subnet used for regional VNet integration."
  type        = string
}

variable "uami_id" {
  description = "The resource ID of the user assigned managed identity attached to the function app."
  type        = string
}

variable "uami_client_id" {
  description = "The client ID of the user assigned managed identity used for identity-based storage access."
  type        = string
}

variable "uami_tenant_id" {
  description = "The tenant ID of the user assigned managed identity used for identity-based storage access."
  type        = string
}

variable "application_insights_connection_string" {
  description = "The Application Insights connection string used for telemetry."
  type        = string
  sensitive   = true
}

variable "service_name" {
  description = "The azd service name (from azure.yaml) used to tag the function app so azd can deploy to it."
  type        = string
}

variable "extra_app_settings" {
  description = "Additional application settings to merge into the function app (e.g. Service Bus namespace, SQL connection string)."
  type        = map(string)
  default     = {}
}

variable "runtime_name" {
  description = "Runtime of the Linux Function App. Possible values are: `node`, `dotnet-isolated`, `powershell`, `python`, `java`, and `custom`."
  type        = string

  validation {
    condition     = contains(["node", "dotnet-isolated", "powershell", "python", "java", "custom"], var.runtime_name)
    error_message = "runtime_name must be one of: `node`, `dotnet-isolated`, `powershell`, `python`, `java`, and `custom`."
  }
}

variable "runtime_version" {
  description = "Version of the runtime. Dependent on your runtime."
  type        = string
}
