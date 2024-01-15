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

module "network" {
  source      = "./network"
  region      = var.region
  name        = var.name
  environment = var.environment
}

module "s3" {
  source      = "./s3"
  region      = var.region
  name        = var.name
  bucket_name = "bedrock-qa-bucket-tf"
  environment = var.environment
}

module "ecr" {
  source      = "./ecr"
  region      = var.region
  name        = var.name
  environment = var.environment
}

module "ecs" {
  source                         = "./ecs"
  region                         = var.region
  name                           = var.name
  environment                    = var.environment
  ecr_repository_url             = module.ecr.ecr_repository_url
  target_group_arn               = module.network.target_group_arn
  subnets                        = module.network.subnets
  ecs_service_security_groups_id = module.network.ecs_service_security_groups_id
  ecs_task_execution_role_arn    = module.iam.ecs_task_execution_role_arn
}

module "iam" {
  source      = "./iam"
  region      = var.region
  name        = var.name
  environment = var.environment
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