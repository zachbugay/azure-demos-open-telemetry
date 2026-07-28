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

variable "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace to attach the transformation DCR to."
  type        = string
}

variable "transformations" {
  description = <<-EOT
    Map of ingestion-time transformations, keyed by destination Log Analytics table name
    (e.g. "AppTraces", "StorageBlobLogs", "FunctionAppLogs"). The value is a KQL query starting with
    the virtual `source` table. Set to {} to disable and create no DCR.
  EOT
  type        = map(string)
  default     = {}
}

variable "resource_token" {
  description = "A suffix string to centrally mitigate resource name collisions."
  type        = string
}
