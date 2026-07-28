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

variable "entra_administrator_login" {
  description = "The login username (display name) of the Entra ID administrator for the SQL Server."
  type        = string
}

variable "entra_administrator_object_id" {
  description = "The Entra ID object ID of the user, group, or service principal set as the SQL Server administrator."
  type        = string
}

variable "entra_administrator_tenant_id" {
  description = "The Entra ID tenant ID of the SQL Server administrator."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "The resource ID of the subnet in which the SQL Server private endpoint is created."
  type        = string
}

variable "sql_private_dns_zone_id" {
  description = "The resource ID of the private DNS zone (privatelink.database.windows.net) used to resolve the SQL Server private endpoint."
  type        = string
}

variable "authorized_ip_addresses" {
  description = "List of public IP addresses allowed to reach the SQL Server through the server firewall when public network access is enabled. The deploying machine's public IP is added by the root module."
  type        = list(string)
  default     = []
}

variable "authorized_subnet_ids" {
  description = "List of subnet resource IDs allowed to reach the SQL Server through virtual network firewall rules. Each subnet must have the 'Microsoft.Sql' service endpoint enabled."
  type        = list(string)
  default     = []
}

variable "database_sku_name" {
  description = "The SKU (service tier) name for the SQL Database (e.g. Basic, S0, GP_S_Gen5_2)."
  type        = string
  default     = "S0"
}

variable "database_max_size_gb" {
  description = "The maximum size of the SQL Database in gigabytes."
  type        = number
  default     = 2
}

variable "collation" {
  description = "The collation of the SQL Database."
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}
