variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "environment_name" {
  description = "The name of the azd environment to be deployed"
  type        = string
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

variable "publisher_name" {
  description = "The name of the publisher/company of the API Management instance."
  type        = string
}

variable "publisher_email" {
  description = "The email of the publisher/company of the API Management instance."
  type        = string
}

variable "sku_name" {
  description = "The pricing tier of this API Management service"
  default     = "BasicV2"
  type        = string
  validation {
    condition     = contains(["Basic", "BasicV2", "Consumption", "Developer", "Premium", "PremiumV2", "Standard", "StandardV2"], var.sku_name)
    error_message = "The sku must be one of the following: Basic, BasicV2, Consumption, Developer, Premium, PremiumV2, Standard, StandardV2."
  }
}

variable "sku_count" {
  description = "The instance size of this API Management service."
  default     = 1
  type        = number
  validation {
    condition     = contains([1, 2], var.sku_count)
    error_message = "The sku_count must be one of the following: 1, 2."
  }
}

variable "subnet_id" {
  description = "The resource ID of the subnet (delegated to Microsoft.Web/serverFarms) used for API Management VNet integration. Set to null to disable VNet integration."
  type        = string
  default     = null
}

variable "virtual_network_type" {
  description = "The type of VNet integration. StandardV2 supports 'External' (outbound integration, public inbound); 'Internal' requires PremiumV2. Use 'None' to disable."
  type        = string
  default     = "External"
  validation {
    condition     = contains(["None", "External", "Internal"], var.virtual_network_type)
    error_message = "The virtual_network_type must be one of: None, External, Internal."
  }
}

variable "application_insights_enabled" {
  description = "Whether to create the Application Insights logger and diagnostic for API Management. Must be known at plan time (unlike the id/name inputs, which are computed during apply)."
  type        = bool
  default     = false
}

variable "application_insights_name" {
  description = "The name of the Application Insights instance APIM logs to. Set to null to disable Application Insights diagnostics."
  type        = string
  default     = null
}

variable "application_insights_id" {
  description = "The resource ID of the Application Insights instance APIM logs to. Set to null to disable Application Insights diagnostics."
  type        = string
  default     = null
}

variable "uami_id" {
  description = "The resource ID of the user-assigned managed identity to assign to API Management (used for keyless Application Insights ingestion). Set to null to disable."
  type        = string
  default     = null
}

variable "uami_client_id" {
  description = "The client ID of the user-assigned managed identity APIM uses to authenticate to Application Insights."
  type        = string
  default     = null
}
