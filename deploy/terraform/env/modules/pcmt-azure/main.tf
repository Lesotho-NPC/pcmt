data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_ssh_public_key" "pcmt" {
  name = var.ssh_key_name
  resource_group_name = local.resource_group_name
}

locals {
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

