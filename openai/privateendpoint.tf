# Private endpoint data dependencies 
# Subnet where PE will be created 
data "azurerm_subnet" "pe_subnet" {
  for_each = var.private_endpoint

  name                 = each.value.subnet_name
  resource_group_name  = each.value.vnet_rg_name
  virtual_network_name = each.value.vnet_name
}

# Resource group of the VNET-Subnet where PE will be created 
data "azurerm_resource_group" "pe_vnet_rg" {
  for_each = var.private_endpoint

  name = each.value.vnet_rg_name
}

data "azurerm_virtual_network" "vnet" {
  for_each = var.private_endpoint

  name                = each.value.vnet_name
  resource_group_name = each.value.vnet_rg_name
}

locals {
  private_dns_zone_id   = data.azurerm_private_dns_zone.dns_zone.id
  private_dns_zone_name = data.azurerm_private_dns_zone.dns_zone.name
}

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoint

  location            = data.azurerm_resource_group.pe_vnet_rg[each.key].location
  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.pe_vnet_rg[each.key].name
  subnet_id           = data.azurerm_subnet.pe_subnet[each.key].id
  tags = merge(local.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "c8b6b17b0b28a2aa54a3e734b9bd0a0d0ef5c267"
    avm_git_file             = "privateendpoint.tf"
    avm_git_last_modified_at = "2023-05-04 10:08:08"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-openai"
    avm_yor_trace            = "165734a0-e538-423c-a70a-c13ca973ad6f"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

  private_service_connection {
    is_manual_connection           = each.value.is_manual_connection
    name                           = each.value.private_service_connection_name
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = var.pe_subresource
  }
  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_entry_enabled ? ["private_dns_zone_group"] : []

    content {
      name                 = local.private_dns_zone_name
      private_dns_zone_ids = [local.private_dns_zone_id]
    }
  }

  depends_on = [
    azurerm_cognitive_deployment.this,
  ]
}


data "azurerm_private_dns_zone" "dns_zone" {
  name                = var.private_dns_zone.name
  resource_group_name = var.private_dns_zone.resource_group_name
}