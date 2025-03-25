terraform {
  required_version = "~> 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "pcmt-terraform-states"
    key    = "pcmt-demo-pc-io.tf"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = var.aws-region
}
