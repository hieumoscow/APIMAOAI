resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = "rg-${local.name_convention}"
}

locals {
  name_convention = "${var.appname}-${var.environment}-${var.location}"
  
}

data "azurerm_client_config" "current" {}
