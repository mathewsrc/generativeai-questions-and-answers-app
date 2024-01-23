resource "aws_api_gateway_vpc_link" "example" {
  name        = var.vpc_link_name
  description = "VPC Link for API Gateway"
  target_arns = [var.laod_balancer_arn]
  tags = {
    Name = var.name
    Environment = var.environment
  }
}