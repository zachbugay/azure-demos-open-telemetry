output "id" {
  description = "The resource ID of the function app."
  value = one(concat(
    azurerm_linux_function_app.func[*].id,
    azurerm_function_app_flex_consumption.func[*].id,
  ))
}

output "name" {
  description = "The name of the function app."
  value = one(concat(
    azurerm_linux_function_app.func[*].name,
    azurerm_function_app_flex_consumption.func[*].name,
  ))
}

output "default_hostname" {
  description = "The default hostname of the function app."
  value = one(concat(
    azurerm_linux_function_app.func[*].default_hostname,
    azurerm_function_app_flex_consumption.func[*].default_hostname,
  ))
}
