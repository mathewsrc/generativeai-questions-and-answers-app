# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/vpc-endpoints.html
# https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html

# Create a VPC for ECR 
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets.*.id

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

  tags = {
    Name        = "ECR Docker VPC Endpoint"
    Environment = var.environment
  }
}

# Create a VPC Endpoint for ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets.*.id

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

  tags = {
    Name        = "ECR API VPC Endpoint"
    Environment = var.environment
  }
}

# Create a VPC Endpoint for Secrests Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets.*.id

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

  tags = {
    Name        = "Secrets Manager VPC Endpoint"
    Environment = var.environment
  }
}

# Create a VPC Endpoint for CloudWatch
resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets.*.id
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

  tags = {
    Name        = "CloudWatch VPC Endpoint"
    Environment = var.environment
  }
}

# Create a VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.main.default_route_table_id]

  tags = {
    Name        = "S3 VPC Endpoint Gateway"
    Environment = var.environment
  }
}