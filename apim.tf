data "azurerm_subnet" "apim_subnet" {
  name                 = azurerm_subnet.subnet[var.apim.vnet_subnet_key].name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}
resource "azurerm_public_ip" "apim_pip" {
  name                = "pip-apim-${var.apim.name}-${local.name_convention}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = "${var.apim.name}-${local.name_convention}"
}

resource "azurerm_api_management" "api" {
  name                 = "${var.apim.name}-${local.name_convention}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  publisher_email      = var.apim.publisher_email
  publisher_name       = var.apim.publisher_name
  sku_name             = var.apim.sku_name
  virtual_network_type = var.apim.virtual_network_type
  public_ip_address_id = azurerm_public_ip.apim_pip.id 
  # TODO stv2 upgrade

  virtual_network_configuration {
    subnet_id = data.azurerm_subnet.apim_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }
}

locals {
  oai_fqdns = {for key, value in var.openai.regions :
    key => {
      name = "openai-${value.name}"
      path = "https://oai-${var.appname}-${var.environment}-${value.location}-${value.name}.openai.azure.com"
    }
  }

  # openai_agw_endpoint = "https://${azurerm_private_dns_zone.agw_dns_zone.name}"
  # openai_agw_apis = { for key, value in var.openai.deployment :
  #   key => {
  #     name = value.name
  #     path = "${local.openai_agw_endpoint}/openai/deployments/${value.name}/chat/completions?api-version=${var.openai.api_version}"
  #   }
  # }
}

output "oai_fqdns" {
  value = local.oai_fqdns
}


/*
  Resource: azurerm_api_management_product
  Description: Represents an API product in Azure API Management.
  - product_id: The unique identifier for the API product.
  - api_management_name: The name of the API Management service.
  - resource_group_name: The name of the resource group containing the API Management service.
  - display_name: The display name of the API product.
  - subscription_required: Specifies whether a subscription is required to access the API product.
  - approval_required: Specifies whether approval is required to access the API product.
  - published: Specifies whether the API product is published and available for use.
*/

resource "azurerm_api_management_product" "api_product_open" {
  product_id            = "open"
  api_management_name   = azurerm_api_management.api.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Starter Product"
  subscription_required = false
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_api" "openai_api" {
  for_each            = local.oai_fqdns
  name                = "${each.value.name}"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.api.name
  revision            = "1"
  display_name        = "${each.value.name}"
  service_url         = each.value.path
  path                = "${each.value.name}"
  protocols           = ["https"]
}


# resource "azurerm_api_management_product_api" "openai_product_api" {
#   for_each            = local.openai_agw_apis
#   product_id          = azurerm_api_management_product.api_product_open.product_id
#   api_name            = azurerm_api_management_api.openai_api[each.key].name
#   api_management_name = azurerm_api_management.api.name
#   resource_group_name = azurerm_resource_group.rg.name
# }

resource "azurerm_api_management_api_operation" "openai_api_operation" {
  for_each            = local.oai_fqdns
  operation_id        = each.value.name
  api_name            = azurerm_api_management_api.openai_api[each.key].name
  api_management_name = azurerm_api_management.api.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = each.value.name
  method              = "POST"
  url_template        = "/*"
  description         = "OpenAI POST Operation"
}

resource "azurerm_api_management_api_operation" "openai_api_operation_probe" {
  for_each            = local.oai_fqdns
  operation_id        = "${each.value.name}-probe"
  api_name            = azurerm_api_management_api.openai_api[each.key].name
  api_management_name = azurerm_api_management.api.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Probe"
  method              = "GET"
  url_template        = "/status-0123456789abcdef"
  description         = "OpenAI Probe"
}

# resource "azurerm_api_management_api_policy" "openai_api_policy" {
#   for_each            = local.openai_agw_apis
#   api_name            = azurerm_api_management_api.openai_api[each.key].name
#   api_management_name = azurerm_api_management.api.name
#   resource_group_name = azurerm_resource_group.rg.name
#   xml_content         = file("${path.module}/apimassets/openai.xml")
# }

# resource "azurerm_api_management_backend" "agw_backend" {
#   name                = "agw_backend"
#   resource_group_name = azurerm_resource_group.rg.name
#   api_management_name = azurerm_api_management.api.name
#   protocol            = "http"
#   url                 = local.openai_agw_endpoint
#   tls {
#     validate_certificate_chain = false
#   }
# }

resource "azurerm_role_assignment" "apim_openai_role_assignment" {
  for_each = {for key, value in module.openai : key => value.id}
  scope                = each.value
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_api_management.api.identity[0].principal_id
}



