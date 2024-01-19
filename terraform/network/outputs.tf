output "load_balancer_name" {
  value = aws_lb.load_balancer.name
}

output "target_group_arn" {
  value = aws_lb_target_group.lb_target_group.arn
}

output "service_security_group_ids" {
  value = tolist([aws_security_group.service_security_group.id])
}

output "vpc_id" {
  value = aws_default_vpc.default_vpc.id
}

output "subnets" {
  value = tolist([aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id])
}

output "app_url" {
  value = aws_lb.load_balancer.dns_name
}