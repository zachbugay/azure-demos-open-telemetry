variable "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace where diagnostics data is sent."
  type        = string
}

variable "diagnostic_targets" {
  description = <<-EOT
    Map of diagnostic settings to create, keyed by a short name used in the setting name.
    Each entry configures one Azure resource:
      - resource_id        : the target resource ID (may be a sub-resource, e.g. <storage>/blobServices/default).
      - log_category_group : the diagnostic log category group to enable ("allLogs" or "audit"); null to enable no logs.
      - metric_categories  : list of metric categories to enable (e.g. ["AllMetrics"] or ["Transaction"]).
    At least one log category group or metric category must be enabled per target.
  EOT
  type = map(object({
    resource_id        = string
    log_category_group = optional(string)
    metric_categories  = optional(list(string), [])
  }))
}
