# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region
data "aws_region" "current" {}

# Get the availability zones for the current region
data "aws_availability_zones" "available" {}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr_block
  enable_dns_support   = true # Required for VPC endpoints
  enable_dns_hostnames = true # Required for VPC endpoints
}

# Create public subnets
resource "aws_subnet" "public_subnets" {
  count                   = length(var.aws_public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.aws_public_subnet_cidr_blocks, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name        = "public-subnets-${count.index}"
    Application = var.application_name
    Environment = var.environment
  }
}

# Create private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.aws_private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.aws_private_subnet_cidr_blocks, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name        = "private-subnets-${count.index}"
    Application = var.application_name
    Environment = var.environment
  }
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Create a Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "main-route-table"
    Application = var.application_name
    Environment = var.environment
  }
}

# Create a security group for the load balancer
resource "aws_security_group" "lb" {
  vpc_id = aws_vpc.main.id
  name   = var.security_group_name_lb
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Name        = var.security_group_name_lb
    Application = var.application_name
  }
}

# Create a security group for the ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name   = var.security_group_name_ecs_tasks
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  # The security group attached to the VPC endpoint must allow incoming 
  # connections on TCP port 443 from the private subnet of the VPC.
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    prefix_list_ids = [
      aws_vpc_endpoint.s3.prefix_list_id
    ]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  tags = {
    Environment = var.environment
    Name        = var.security_group_name_ecs_tasks
    Application = var.application_name
  }
}