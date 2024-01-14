resource "aws_ecr_repository" "bedrock" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Application = var.name
    Name        = var.ecr_name
  }
}
