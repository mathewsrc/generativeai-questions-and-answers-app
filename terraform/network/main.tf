# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region
data "aws_region" "current" {}

# Create a default VPC
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "Default VPC"
  }
}

# Create a default subnet for us-east-1a and us-east-1b
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "Default subnet for us-east-1a"
  }
  depends_on = [aws_default_vpc.default_vpc]
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "Default subnet for us-east-1b"
  }
  depends_on = [aws_default_vpc.default_vpc]
}

# Create a ECS security group
resource "aws_security_group" "security_group" {
  vpc_id = aws_default_vpc.default_vpc.id
  name   = var.security_group_name
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
    Name        = var.security_group_name
  }
}

# Create a load balancer
resource "aws_lb" "load_balancer" {
  name               = var.load_balance_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group.id]
  subnets = [
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
    Application = var.name
    Name        = var.load_balance_name
  }
}

# Create a service security group
resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = [aws_security_group.security_group.id]
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
    Name        = var.security_group_name
  }
}

# Create a ECS load balancer target group
resource "aws_lb_target_group" "lb_target_group" {
  name        = var.load_balancer_target_group_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_default_vpc.default_vpc.id
  target_type = "ip"
  tags = {
    Environment = var.environment
    Application = var.name
    Name        = var.load_balancer_target_group_name
  }
}

# Create a ECS load balancer listener
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }

  tags = {
    Environment = var.environment
    Application = var.name
  }
}