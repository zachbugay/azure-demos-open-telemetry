locals {
  role_assignments_flat = {
    for item in flatten([
      for group_key, group in var.role_assignments : [
        for idx, principal_id in group.principal_ids : [
          for role in group.role_definition_names : {
            key                  = "${group_key}-${idx}-${role}"
            scope                = group.scope
            principal_id         = principal_id
            role_definition_name = role
          }
        ]
      ]
    ]) : item.key => item
  }
}

resource "azurerm_role_assignment" "this" {
  for_each             = local.role_assignments_flat
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
