terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"  
  default_tags {
    tags = {
      Name = var.name
    }
  }
}

# module "iam" {
#   source           = "./iam"
#   region           = data.aws_region.current.name
#   application_name = var.name
#   environment      = var.environment
# }

module "secrets_manager" {
  source      = "./secrets_manager"
  environment = var.environment
  region      = data.aws_region.current.name
}

module "network" {
  source           = "./network"
  region           = data.aws_region.current.name
  application_name = var.name
  environment      = var.environment
}

module "s3" {
  source                     = "./s3"
  region                     = data.aws_region.current.name
  application_name           = var.name
  bucket_name                = "bedrock-qa-bucket-tf"
  environment                = var.environment
  subfolder                  = "cnu"
  wait_for_lambda_deployment = module.lambda.wait_for_lambda_deployment
}

module "lambda" {
  source           = "./lambda"
  application_name = var.name
  environment      = var.environment
  s3_bucket_id     = module.s3.s3_bucket_id
  s3_bucket_arn    = module.s3.s3_bucket_arn
}

module "load_balancer" {
  source           = "./load_balancer"
  region           = data.aws_region.current.name
  application_name = var.name
  environment      = var.environment
  public_subnets   = module.network.public_subnets
  vpc_id           = module.network.vpc_id
  container_port   = var.container_port
}

module "ecr" {
  source           = "./ecr"
  region           = data.aws_region.current.name
  application_name = var.name
  environment      = var.environment
}

module "ecs" {
  source                      = "./ecs"
  region                      = data.aws_region.current.name
  application_name            = var.name
  environment                 = var.environment
  ecr_repository_url          = module.ecr.ecr_repository_url
  ecr_repository_name         = module.ecr.ecr_repository_name
  vpc_id                      = module.network.vpc_id
  private_subnets             = module.network.private_subnets
  nlb_target_group_arn        = module.load_balancer.nlb_target_group_arn
  container_port              = var.container_port
  ecs_tasks_security_group_id = [module.network.ecs_tasks_security_group_id]
}

module "api_gateway" {
  source           = "./api_gateway"
  region           = data.aws_region.current.name
  application_name = var.name
  environment      = var.environment
  nlb_dns_name     = module.load_balancer.nlb_dns_name
  nlb_arn          = module.load_balancer.nlb_arn
  container_port   = var.container_port
}

# Define the local backend for the Terraform state
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# Define the S3 backend for the Terraform state
terraform {
  backend "s3" {
    bucket = "terraform-bucket-state-tf"
    key    = "state/terraform.tfstate"
  }
}

