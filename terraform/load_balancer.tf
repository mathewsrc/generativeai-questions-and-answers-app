resource "aws_security_group" "ecs_load_balancer_security_group" {
  vpc_id = aws_default_vpc.default_vpc.id
  name   = var.ecs_security_group_name
  # Inbound and outbound rules
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
    Environment = "production"
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = var.load_balancer_target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default_vpc.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.ecs_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn #
  }
}