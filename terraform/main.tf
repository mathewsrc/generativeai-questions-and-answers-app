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

module "iam" {
  source      = "./iam"
  region      = var.region
  name        = var.name
  environment = var.environment
}

module "network" {
  source      = "./network"
  region      = var.region
  name        = var.name
  environment = var.environment
}

#module "s3_cnu" {
#  source      = "./s3"
#  region      = var.region
#  name        = var.name
#  bucket_name = "bedrock-qa-bucket-tf"
#  environment = var.environment
#  subfolder   = "cnu"
#}

#module "s3_immigration" {
#  source      = "./s3"
#  region      = var.region
#  name        = var.name
#  bucket_name = "bedrock-qa-bucket-tf"
#  environment = var.environment
#  subfolder   = "immigration"
#}

# Use Qdrant Cloud steady
# module "opensearchserveless" {
#   source             = "./opensearch"
#   region             = var.region
#   name               = var.name
#   environment        = var.environment
#   subnet_ids         = module.network.subnets
#   vpc_id             = module.network.vpc_id
#   security_group_ids = module.network.service_security_group_ids
# }

module "ecr" {
  source      = "./ecr"
  region      = var.region
  name        = var.name
  environment = var.environment
}

module "ecs" {
  source                      = "./ecs"
  region                      = var.region
  name                        = var.name
  environment                 = var.environment
  ecr_repository_url          = module.ecr.ecr_repository_url
  ecr_repository_name         = module.ecr.ecr_repository_name
  target_group_arn            = module.network.target_group_arn
  subnets                     = module.network.subnets
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  service_security_group_ids  = module.network.service_security_group_ids
}

module "api_gateway" {
  source                 = "./api_gateway"
  region                 = var.region
  name                   = var.name
  environment            = var.environment
  load_balancer_arn      = module.network.load_balancer_arn
  load_balancer_dns_name = module.network.load_balancer_dns_name
}

# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

terraform {
  backend "s3" {
    bucket = "terraform-bucket-state-tf"
    key    = "state/terraform.tfstate"
  }
}

