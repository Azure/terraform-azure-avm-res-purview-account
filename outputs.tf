output "name" {
  description = "The name of the Microsoft Purview account."
  value       = azapi_resource.this.name
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.managed_dns_zone_group : azurerm_private_endpoint.unmanaged_dns_zone_group
}

output "resource" {
  description = "Selected Microsoft Purview account resource properties returned by Azure."
  value       = azapi_resource.this.output
}

output "resource_id" {
  description = "The resource ID of the Microsoft Purview account."
  value       = azapi_resource.this.id
}
