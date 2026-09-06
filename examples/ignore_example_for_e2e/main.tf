terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"
}

locals {
  purview_regions = [for region in module.regions.regions : region if contains([
    "australiaeast",
    "brazilsouth",
    "canadacentral",
    "canadaeast",
    "centralindia",
    "eastus",
    "eastus2",
    "francecentral",
    "germanywestcentral",
    "japaneast",
    "koreacentral",
    "northeurope",
    "qatarcentral",
    "southafricanorth",
    "southcentralus",
    "southeastasia",
    "swedencentral",
    "switzerlandnorth",
    "uaenorth",
    "uksouth",
    "westcentralus",
    "westeurope",
    "westus",
    "westus2",
    "westus3",
  ], region.name)]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.purview_regions) - 1
  min = 0
}

## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

# This is required for resource modules
resource "azapi_resource" "resource_group" {
  location               = local.purview_regions[random_integer.region_index.result].name
  name                   = module.naming.resource_group.name_unique
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  response_export_values = []
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"

  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location         = azapi_resource.resource_group.location
  name             = module.naming.purview_account.name_unique
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = var.enable_telemetry # see variables.tf
  managed_identities = {
    system_assigned = true
  }
}
