resource "azurerm_linux_virtual_machine" "pcmt_vm" {
  name                = var.domain_name
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.pcmt_nic.id,
  ]


  admin_ssh_key {
    username   = "adminuser"
    public_key = data.azurerm_ssh_public_key.pcmt.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
