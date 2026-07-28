resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_targets

  name                           = "diag-${each.key}"
  target_resource_id             = each.value.resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = each.value.log_category_group == null ? [] : [each.value.log_category_group]
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = toset(each.value.metric_categories)
    content {
      category = enabled_metric.value
    }
  }

  # Azure's API doesn't reliably persist/report this field, causing Terraform to
  # perpetually plan a no-op update. See:
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/20140
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}
