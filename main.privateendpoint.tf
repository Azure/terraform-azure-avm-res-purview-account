resource "azurerm_private_endpoint" "managed_dns_zone_group" {
  for_each = var.private_endpoints_manage_dns_zone_group ? var.private_endpoints : {}

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.name}-${each.key}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : local.parent_resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azapi_resource.this.id
    subresource_names              = [local.private_endpoint_subresource_name]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = local.private_endpoint_subresource_name
      subresource_name   = local.private_endpoint_subresource_name
    }
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

# The PE resource when we are managing **not** the private_dns_zone_group block
# An example use case is customers using Azure Policy to create private DNS zones
# e.g. <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale>
resource "azurerm_private_endpoint" "unmanaged_dns_zone_group" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.name}-${each.key}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : local.parent_resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = azapi_resource.this.id
    subresource_names              = [local.private_endpoint_subresource_name]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = local.private_endpoint_subresource_name
      subresource_name   = local.private_endpoint_subresource_name
    }
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

resource "azurerm_management_lock" "private_endpoint_lock" {
  for_each = { for k, v in var.private_endpoints : k => v if v.lock != null }

  lock_level = each.value.lock.kind
  name       = coalesce(each.value.lock.name, "lock-${each.value.lock.kind}")
  scope      = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.managed_dns_zone_group[each.key].id : azurerm_private_endpoint.unmanaged_dns_zone_group[each.key].id
  notes      = each.value.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "private_endpoint_role_assignment" {
  for_each = local.private_endpoint_role_assignments

  principal_id                           = each.value.role_assignment_value.principal_id
  scope                                  = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.managed_dns_zone_group[each.value.pe_key].id : azurerm_private_endpoint.unmanaged_dns_zone_group[each.value.pe_key].id
  condition                              = each.value.role_assignment_value.condition
  condition_version                      = each.value.role_assignment_value.condition_version
  delegated_managed_identity_resource_id = each.value.role_assignment_value.delegated_managed_identity_resource_id
  principal_type                         = each.value.role_assignment_value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_assignment_value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_assignment_value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_assignment_value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_assignment_value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.role_assignment_value.skip_service_principal_aad_check
}

resource "azurerm_private_endpoint_application_security_group_association" "application_security_group_association" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.managed_dns_zone_group[each.value.pe_key].id : azurerm_private_endpoint.unmanaged_dns_zone_group[each.value.pe_key].id
}
