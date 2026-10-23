terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "azapi" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.13.0"

  location         = var.location
  enable_telemetry = var.enable_telemetry
  is_recommended   = true
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

resource "random_integer" "region_index" {
  max = length(local.purview_regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "resource_group" {
  location               = local.purview_regions[random_integer.region_index.result].name
  name                   = module.naming.names.resource_group.name_unique
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-11-01"
  response_export_values = []
}

module "test" {
  source = "../../"

  location         = azapi_resource.resource_group.location
  name             = module.naming.names.purview_account.name_unique
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = var.enable_telemetry
  managed_identities = {
    system_assigned = true
  }
}
