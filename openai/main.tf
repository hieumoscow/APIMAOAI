# resource "random_integer" "this" {
#   max = 999999
#   min = 100000
# }
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}


locals {
  tags = var.default_tags_enabled ? {
    Application_Name = var.application_name
    Environment      = var.environment
  } : {}
  location = coalesce(var.location, data.azurerm_resource_group.this.location)
}

resource "azurerm_cognitive_account" "this" {
  kind                               = "OpenAI"
  location                           = local.location
  name                               = var.account_name
  resource_group_name                = data.azurerm_resource_group.this.name
  custom_subdomain_name              = var.account_name
  sku_name                           = var.sku_name
  dynamic_throttling_enabled         = var.dynamic_throttling_enabled
  fqdns                              = var.fqdns
  local_auth_enabled                 = var.local_auth_enabled
  outbound_network_access_restricted = var.outbound_network_access_restricted
  public_network_access_enabled      = true#var.public_network_access_enabled

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
}

resource "azurerm_cognitive_deployment" "this" {
  for_each = var.deployment

  cognitive_account_id = azurerm_cognitive_account.this.id
  name                 = each.value.name
  rai_policy_name      = each.value.rai_policy_name

  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }
  scale {
    type = each.value.scale_type
    capacity = each.value.capacity
  }
}

output "name" {
  value = azurerm_cognitive_account.this.name
}

output "id" {
  value = azurerm_cognitive_account.this.id
}
