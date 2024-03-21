data "azurerm_subnet" "pe_subnet" {
  name                 = azurerm_subnet.subnet[var.private_endpoint_subnet_key].name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

module "openai" {
  source              = "./openai"
  for_each            = var.openai.regions
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = "oai-${var.appname}-${var.environment}-${each.value.location}-${each.value.name}"
  location            = each.value.location
  sku_name            = var.openai.sku_name
  private_dns_zone = {
    name                = azurerm_private_dns_zone.dns_zone.name
    resource_group_name = azurerm_resource_group.rg.name
  }
  private_endpoint = {
    "pe_endpoint" = {
      private_dns_entry_enabled       = true
      is_manual_connection            = false
      name                            = "${each.value.name}_pe_one"
      private_service_connection_name = "${each.value.name}_pe_one_connection"
      subnet_name                     = data.azurerm_subnet.pe_subnet.name
      vnet_name                       = azurerm_virtual_network.vnet.name
      vnet_rg_name                    = azurerm_resource_group.rg.name
    }
  }
  deployment = var.openai.deployment
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_private_dns_zone.dns_zone,
    azurerm_virtual_network.vnet
  ]
}



resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_link" {

  name                  = "dns_zone_link"
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}
