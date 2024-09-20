data "azurerm_subnet" "instance" {
  name = var.subnet_name
  virtual_network_name = var.network_name 
  resource_group_name = local.resource_group_name
}

resource "azurerm_network_interface" "sso_nic" {
  name                = var.domain_name
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.instance.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sso_public_ip.id
  }
}

resource "azurerm_public_ip" "sso_public_ip" {
  name                = var.domain_name
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
}

data "aws_route53_zone" "domain" {
  name = var.route53_zone_name
}

resource "aws_route53_record" "instance" {
  zone_id  = data.aws_route53_zone.domain.id
  name     = var.domain_name
  type     = "A"
  ttl      = 300
  records  = [azurerm_public_ip.sso_public_ip.ip_address]
}