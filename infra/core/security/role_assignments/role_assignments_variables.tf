variable "role_assignments" {
  description = "Map of named role assignment groups. Each group grants every principal in principal_ids each role in role_definition_names at the given scope."
  type = map(object({
    scope                 = string
    principal_ids         = list(string)
    role_definition_names = list(string)
  }))
}
