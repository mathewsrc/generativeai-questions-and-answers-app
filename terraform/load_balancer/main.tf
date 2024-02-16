# Create a Load Balancer
resource "aws_lb" "lb" {
  name                       = var.nlb_name
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = var.public_subnets
  enable_deletion_protection = false

  tags = {
    Environment = var.environment
    Name        = var.nlb_name
    Terraform   = "true"
    Application = var.application_name
  }
}

# Create a target group
resource "aws_lb_target_group" "target_group" {
  depends_on  = [aws_lb.lb]
  name        = var.target_group_name
  port        = var.container_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

# Redirect traffic from the Load Balancer to the target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.container_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

