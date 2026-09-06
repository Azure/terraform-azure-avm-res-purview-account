output "name" {
  description = "The name of the Microsoft Purview account."
  value       = azapi_resource.this.name
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoint resource IDs created.
  DESCRIPTION
  value       = { for key, private_endpoint in azapi_resource.private_endpoint : key => private_endpoint.id }
}

output "resource_id" {
  description = "The resource ID of the Microsoft Purview account."
  value       = azapi_resource.this.id
}
