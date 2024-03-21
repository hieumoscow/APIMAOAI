resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "log-${local.name_convention}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "shared_apim_insight" {
  name                = "appi-${local.name_convention}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
}


resource "azurerm_application_insights_api_key" "app_insight_key" {
  name                    =  "appi-key-${local.name_convention}"
  application_insights_id = azurerm_application_insights.shared_apim_insight.id
  read_permissions        = ["aggregate", "api", "draft", "extendqueries", "search"]
}