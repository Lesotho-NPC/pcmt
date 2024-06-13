terraform {
  required_version = "~> 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.105.0"
    }

    aws = {
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}

provider "aws" {
  region = var.aws_region
}