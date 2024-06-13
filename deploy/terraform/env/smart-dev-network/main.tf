module "smart-dev-network" {
  source = "../modules/pcmt-azure-network"

  resource_group = var.resource_group
  network_name = var.network_name
}