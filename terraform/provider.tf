terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Name = var.name
    }
  }
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

#terraform {
# backend "remote" {
#    # The name of your Terraform Cloud organization.
#    organization = "mlops-terraform"
#
#    # The name of the Terraform Cloud workspace to store Terraform state files in.
#    workspaces {
#      name = "bedrock-qa-tf"
#    }
#  }
#}