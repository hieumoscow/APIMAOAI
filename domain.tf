resource "azurerm_dns_zone" "domain_dns_zone" {
  count = var.domain_name_registration != null ? 1 : 0

  name                = var.domain_name_registration.name
  resource_group_name = azurerm_resource_group.rg.name
}

module "domain_name_registration" {
  source   = "./domain"
  count = var.domain_name_registration != null ? 1 : 0

#   base_tags           = try(local.global_settings.inherit_tags, false) ? try(local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)].tags, {}) : {}
  dns_zone_id         = azurerm_dns_zone.domain_dns_zone[0].id
  name                = var.domain_name_registration.name
  resource_group_name = azurerm_resource_group.rg.name
  settings            = var.domain_name_registration
}

output "domain_name_registrations" {
  value = module.domain_name_registration
}


