#data "aws_ecr_repository" "bedrock" {
# name = var.ecr_name
#}

resource "aws_ecr_repository" "bedrock" {
  name                 = "bedrock_qa"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
