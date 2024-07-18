resource "azurerm_linux_virtual_machine" "pcmt_vm" {
  name                = var.domain_name
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.pcmt_nic.id,
  ]


  admin_ssh_key {
    username   = "ubuntu"
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

resource "null_resource" "deploy-docker" {
  depends_on = [azurerm_linux_virtual_machine.pcmt_vm]
  triggers = {
    build_number = "${timestamp()}"
  }

  connection {
    user = "ubuntu"
    host = azurerm_public_ip.pcmt_public_ip.ip_address
  }

  provisioner "remote-exec" {
    inline = ["ls"]

    connection {
      type = "ssh"
      user = "ubuntu"
      host = azurerm_public_ip.pcmt_public_ip.ip_address
    }
  }

  provisioner "local-exec" {
    command = "../../script/pcmt-ansible.sh ${azurerm_public_ip.pcmt_public_ip.ip_address} ${var.domain_name}"
  }
}
