variable "appname" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string

}

variable "openai" {
  type = object({
    api_version = string
    regions = map(object({
      name     = string
      location = string
    }))
    sku_name                    = string
    deployment = map(object({
      name          = string
      model_format  = string
      model_name    = string
      model_version = string
      scale_type    = string
      capacity      = number
    }))
    openai_deployment_key = string
  })
}

variable "vnet" {
  type = object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      name              = string
      address_prefixes  = list(string)
      service_endpoints = list(string)
      nsg_key           = optional(string)
      delegations = optional(list(object({
        name = string
        service_delegation = object({
          name    = string
          actions = list(string)
        })
      })))
    }))
  })
}

variable "apim" {
  type = object({
    name                 = string
    sku_name             = string
    publisher_email      = string
    publisher_name       = string
    virtual_network_type = string
    vnet_subnet_key      = string
    apis = map(object({
      name             = string
      display_name     = string
      app_service_key  = string
      apim_policy_xml  = string
      apim_swagger_xml = string
      revision         = string
    }))
  })
}

variable "network_security_groups" {
  type = map(map(object({
    name                       = string
    priority                   = number
    protocol                   = string
    destination_port_range     = string
    access                     = string
    direction                  = string
    source_port_range          = string
    source_address_prefix      = string
    destination_address_prefix = string
  })))
}

variable "application_gateway" {
  type = object({
    name            = string
    vnet_subnet_key = string
    sku_name        = string
    capacity        = number
    certificate_import = optional(object({
      key_vault_name                             = string
      key_vault_resource_group_name              = string
      certificate_name                           = string
      user_assigned_identity_name                = string
      user_assigned_identity_resource_group_name = string
      host_name                                  = string
    }))
  })

}

variable "private_endpoint_subnet_key" {
  type = string
}


variable "domain_name_registration" {
  type = object({
    name               = string
    auto_renew         = bool
    privacy            = bool
    lock_resource      = bool
    dns_zone = object({
      key = string
    })
    contacts = object({
      contactAdmin = object({
        name_first   = string
        name_last    = string
        email        = string
        phone        = string
        organization = string
        job_title    = string
        address1     = string
        address2     = string
        postal_code  = string
        state        = string
        city         = string
        country      = string
      })
      contactBilling = object({
        same_as_admin = bool
      })
      contactRegistrant = object({
        same_as_admin = bool
      })
      contactTechnical = object({
        same_as_admin = bool
      })
    })
  })
  default = null
}

variable "domain_name" {
  type = string
  default = ""
}