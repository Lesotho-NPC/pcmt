data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

locals {
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}