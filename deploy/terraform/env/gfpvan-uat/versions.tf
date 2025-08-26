terraform {
  required_version = "~> 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    profile = "villagereach-gfpvan"
    bucket  = "vr-gfpvan-terraform-states"
    key     = "pcmt-gfpvan-uat.tf"
    region  = "us-east-2"
  }
}

provider "aws" {
  alias   = "villagereach"
  profile = "villagereach"
  region  = var.aws-region
}

provider "aws" {
  alias   = "gfpvan"
  profile = "villagereach-gfpvan"
  region  = var.aws-region
}
