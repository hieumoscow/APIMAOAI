locals {
  subnets = {
    for subnet in var.vnet.subnets : subnet.name => {
      name              = "${subnet.name}"
      address_prefixes  = subnet.address_prefixes
      service_endpoints = coalesce(subnet.service_endpoints, [])
      network_security_group = subnet.nsg_key == null ? {
        id = azurerm_network_security_group.nsgs["default"].id
        } : {
        id = azurerm_network_security_group.nsgs[subnet.nsg_key].id
      }
      delegations = coalesce(subnet.delegations, [])
    }
  }

  subnet_with_network_security_group = {
    for subnet in local.subnets : subnet.name => {
      network_security_group_id = subnet.network_security_group.id
    }
    if subnet.network_security_group != null
  }
}

# module "vnet" {
#   source  = "Azure/subnets/azurerm"
#   version = "1.0.0"

#   resource_group_name           = azurerm_resource_group.rg.name
#   subnets                       = local.subnets
#   virtual_network_address_space = var.vnet.address_space
#   virtual_network_location      = azurerm_resource_group.rg.location
#   virtual_network_name          = "vnet-${local.name_convention}-${var.vnet.name}"
# }

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.name_convention}-${var.vnet.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.vnet.address_space
}

resource "azurerm_subnet" "subnet" {
  for_each = local.subnets

  name                 = "snet-${local.name_convention}-${each.value.name}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = coalesce(each.value.service_endpoints, [])
  dynamic "delegation" {
    for_each = each.value.delegations == null ? [] : each.value.delegations

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  for_each                  = local.subnet_with_network_security_group
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = each.value.network_security_group_id
}

resource "azurerm_network_security_group" "nsgs" {
  for_each            = var.network_security_groups
  name                = each.key
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dynamic "security_rule" {
    for_each = each.value
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      protocol                   = security_rule.value.protocol
      destination_port_range     = security_rule.value.destination_port_range
      access                     = security_rule.value.access
      direction                  = security_rule.value.direction
      source_port_range          = security_rule.value.source_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
