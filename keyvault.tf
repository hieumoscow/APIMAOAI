resource "azurerm_key_vault" "key_vault" {
  name                = "akv${local.name_convention}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault_access_policy" "signed_in_user_access_policy" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
      "Set",
      "Get",
      "List",
      "Delete",
    ]
    certificate_permissions = [
      "Get",
      "List",
      "Import",
    ]
}



# # issue with destroy & recreate https://github.com/terraform-providers/terraform-provider-acme/issues/68#issuecomment-508735169
# # https://community.letsencrypt.org/t/unable-to-regenerate-certificate-with-terraform/80275/2
# # ACME Let's Encrypt only works on public domain

# resource "tls_private_key" "private_key" {

#   algorithm = "RSA"
# }

# resource "acme_registration" "reg" {

#   account_key_pem = tls_private_key.private_key.private_key_pem
#   email_address   = var.email
# }

# resource "random_string" "passwords" {

#   length = 16
# }
# resource "acme_certificate" "certificate" {

#   account_key_pem          = acme_registration.reg.account_key_pem
#   common_name              = var.certificates
#   certificate_p12_password = random_string.passwords.result

#   dns_challenge {
#     provider = "azuredns"
#     config = {
#       AZURE_RESOURCE_GROUP = var.domain_resource_group_name
#     }
#   }
# }


