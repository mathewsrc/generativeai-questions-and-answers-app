resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
  tags = {
    Name = "Default subnet for us-east-1a"
  }
  depends_on = [ aws_default_vpc.default_vpc ]
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
  tags = {
    Name = "Default subnet for us-east-1b"
  }
  depends_on = [ aws_default_vpc.default_vpc ]
}

resource "aws_security_group" "ecs_load_balancer_security_group" {
  vpc_id = aws_default_vpc.default_vpc.id
  name   = var.ecs_security_group_name
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
    Name        = var.ecs_security_group_name
  }
}

resource "aws_lb" "ecs_load_balancer" {
  name               = var.load_balance_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_load_balancer_security_group.id]
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

resource "aws_security_group" "ecs_service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = [aws_security_group.ecs_load_balancer_security_group.id]
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
    Name        = var.ecs_security_group_name
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = var.load_balancer_target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default_vpc.id

  tags = {
    Environment = var.environment
    Application = var.name
    Name        = var.load_balancer_target_group_name
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.ecs_load_balancer.arn
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