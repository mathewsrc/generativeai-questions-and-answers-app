# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region
data "aws_region" "current" {}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = var.aws_vpc_cidr_block
}

# Create public subnets
resource "aws_subnet" "public_subnets" {
  count                   = length(var.aws_public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.aws_public_subnet_cidr_blocks, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Create private subnets
resource "aws_subnet" "private_subnets" {
  count      = length(var.aws_private_subnet_cidr_blocks)
  vpc_id     = aws_vpc.main.id
  cidr_block = element(var.aws_private_subnet_cidr_blocks, count.index)
  tags = {
    Name = "private-subnet-${count.index}"
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
    Name = "main-route-table"
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
    Application = var.name
    Name        = var.security_group_name_lb
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
    Application = var.name
    Name        = var.security_group_name_ecs_tasks
  }
}