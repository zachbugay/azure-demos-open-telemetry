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

variable "private_endpoint_subnet_id" {
  description = "The resource ID of the subnet in which the storage private endpoints are created."
  type        = string
}

variable "storage_private_dns_zone_ids" {
  description = "Map of storage sub-resource (blob, file, table, queue) to the private DNS zone resource ID used to resolve its private endpoint."
  type        = map(string)
}

variable "authorized_ip_ranges" {
  description = "List of public IP addresses or CIDR ranges (no /31 or /32 masks) allowed to access the storage account when public network access is enabled."
  type        = list(string)
  default     = []
}
