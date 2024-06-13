terraform {
  required_version = "~> 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.105.0"
    }
  }

  backend "azurerm" {
    resource_group_name = "WHO"
    storage_account_name = "whopcmt"
    container_name = "tfstate"
    key = "smart-dev-network"
  }
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}