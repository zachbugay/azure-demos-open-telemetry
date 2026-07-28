output "servicebus_namespace_id" {
  description = "The resource ID of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.sb.id
}

output "servicebus_namespace_name" {
  description = "The name of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.sb.name
}

output "servicebus_endpoint" {
  description = "The URL to the Service Bus namespace endpoint."
  value       = azurerm_servicebus_namespace.sb.endpoint
}

output "servicebus_topics" {
  description = "The created Service Bus namespace topics, keyed by topic map key."
  value = {
    for k, topic in azurerm_servicebus_topic.this : k => {
      id   = topic.id
      name = topic.name
    }
  }
}

output "servicebus_queues" {
  description = "The created Service Bus namespace queues, keyed by queue map key."
  value = {
    for k, queue in azurerm_servicebus_queue.this : k => {
      id   = queue.id
      name = queue.name
    }
  }
}

output "servicebus_fully_qualified_namespace" {
  description = "The fully qualified namespace of the Service Bus (for identity-based connections)."
  value       = "${azurerm_servicebus_namespace.sb.name}.servicebus.windows.net"
}
