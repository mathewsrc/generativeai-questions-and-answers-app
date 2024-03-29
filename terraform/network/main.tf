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
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "public-route-table"
    Application = var.application_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.aws_public_subnet_cidr_blocks)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_route_table.*.id, count.index)
}

# Create an Elastic IP address for the NAT Gateway
resource "aws_eip" "nat" {
  count      = length(var.aws_public_subnet_cidr_blocks)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
}

# Create a NAT Gateway for the public subnets
# Required to allow the ECS tasks to access the internet and communicate with Qdrant Cloud
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(var.aws_public_subnet_cidr_blocks)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)

  tags = {
    Name        = "nat-gateway"
    Subnet      = "public"
    Application = var.application_name
    Environment = var.environment
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private_route_table" {
  count  = length(var.aws_private_subnet_cidr_blocks)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gateway.*.id, count.index)
  }

  tags = {
    Name        = "private-route-table-${count.index}"
    Application = var.application_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.aws_private_subnet_cidr_blocks)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}

# Create a security group for the load balancer
resource "aws_security_group" "lb" {
  vpc_id = aws_vpc.main.id
  name   = var.security_group_name_lb

  # This ingress rule allows incoming HTTP traffic.
  ingress {
    from_port   = 80 # Allow port 80 (HTTP)
    to_port     = 80 # Allow port 80 (HTTP)
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # This egress rule allows all outgoing traffic.
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

  # Allows incoming TCP traffic on the port specified by var.container_port from the IP 
  # addresses in the CIDR block specified by var.aws_vpc_cidr_block.
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  # Allows incoming TCP traffic on port 443 from the IP addresses in 
  # the CIDR block specified by var.# aws_vpc_cidr_block.
  # The security group attached to the VPC endpoint must allow incoming 
  # connections on TCP port 443 from the private subnet of the VPC.
  ingress {
    protocol    = "tcp"
    from_port   = 443 # Allow port 443 (HTTPS)
    to_port     = 443 # Allow port 443 (HTTPS)
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  # Allows all outgoing traffic to any IP address (0.0.0.0/0) and any protocol
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allows outgoing TCP traffic on port 443 to the destinations specified by the
  # prefix list of your S3 VPC endpoint.
  egress {
    from_port = 443 # Allow port 443 (HTTPS)
    to_port   = 443 # Allow port 443 (HTTPS)
    protocol  = "tcp"
    prefix_list_ids = [
      aws_vpc_endpoint.s3.prefix_list_id
    ]
  }

  # Allows outgoing TCP traffic on port 443 to the IP addresses in the CIDR block
  # specified by var.aws_vpc_cidr_block.
  egress {
    from_port   = 443 # Allow port 443 (HTTPS)
    to_port     = 443 # Allow port 443 (HTTPS)
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  tags = {
    Environment = var.environment
    Name        = var.security_group_name_ecs_tasks
    Application = var.application_name
  }
}