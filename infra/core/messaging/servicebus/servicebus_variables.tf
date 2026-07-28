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

variable "sku" {
  description = "The SKU (tier) of the Service Bus namespace."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be one of \"Basic\", \"Standard\", or \"Premium\"."
  }
}

variable "topics" {
  description = "Azure Servicebus Namespace Topics to create."
  type = map(object({
    name                 = string,
    partitioning_enabled = bool
  }))
  default = {}
}

variable "queues" {
  description = "Azure Servicebus Queues to create."
  type = map(object({
    name                 = string,
    partitioning_enabled = bool
  }))
  default = {}
}
