resource "azurerm_storage_container" "pcmt-backup" {
  name                  = var.storage_container_name
  storage_account_name  = "whopcmt"
  container_access_type = "private"
}