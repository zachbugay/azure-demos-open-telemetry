# Input variables for the module

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

variable "function_app_sku" {
  description = "The Azure Functions hosting plan to deploy."
  type        = string
  default     = "flex_consumption"

  validation {
    condition     = contains(["flex_consumption", "functions_premium"], var.function_app_sku)
    error_message = "sku must be either \"flex_consumption\" or \"functions_premium\"."
  }
}

variable "service_bus_sku" {
  description = "SKU for the Azure Service Bus."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.service_bus_sku)
    error_message = "sku must be one of \"Basic\", \"Standard\", or \"Premium\"."
  }
}

variable "apim_sku_name" {
  description = "The pricing tier of this API Management service"
  default     = "BasicV2"
  type        = string
  validation {
    condition     = contains(["Basic", "BasicV2", "Consumption", "Developer", "Premium", "PremiumV2", "Standard", "StandardV2"], var.apim_sku_name)
    error_message = "The sku must be one of the following: Basic, BasicV2, Consumption, Developer, Premium, PremiumV2, Standard, StandardV2."
  }
}

variable "apim_sku_count" {
  description = "The instance size of this API Management service."
  default     = 1
  type        = number
  validation {
    condition     = contains([1, 2], var.apim_sku_count)
    error_message = "The sku_count must be one of the following: 1, 2."
  }
}

variable "apim_publisher_email" {
  description = "A publisher email to assign to Azure API Management"
  type        = string

}
variable "apim_publisher_name" {
  description = "A publisher name to assign to Azure API Management"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space that is used by the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "authorized_ip_ranges" {
  description = "Additional public IP addresses or CIDR ranges (no /31 or /32 masks) allowed to access the storage account. The deploying machine's public IP is always allowed."
  type        = list(string)
  default     = []
}
