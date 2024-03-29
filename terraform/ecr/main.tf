# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region
data "aws_region" "current" {}

# Create an ECR repository for ECS
resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.ecr_name_ecs
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = false

  tags = {
    Environment = var.environment
    Application = var.application_name
    Name        = var.ecr_name_ecs
  }
}

# Create an ECR repository for Lambda
resource "aws_ecr_repository" "lambda_repo" {
  name                 = var.ecr_name_lambda
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = false

  tags = {
    Environment = var.environment
    Application = var.application_name
    Name        = var.ecr_name_lambda
  }
}
