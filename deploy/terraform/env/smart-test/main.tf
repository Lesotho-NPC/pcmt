module "pcmt_azure" {
  source = "../modules/pcmt-azure"

  resource_group = var.resource_group
  ssh_key_name = var.ssh_key_name
  network_name = var.network_name
  subnet_name = var.subnet_name
  aws_region = var.aws_region
  route53_zone_name = var.route53_zone_name
  domain_name = var.domain_name
  storage_container_name = replace(var.domain_name, ".", "-")
}