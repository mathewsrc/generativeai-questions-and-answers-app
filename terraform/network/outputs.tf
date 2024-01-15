output "load_balancer_name" {
  value = aws_lb.ecs_load_balancer.name
}

output "target_group_arn" {
  value = aws_lb_target_group.lb_target_group.arn
}

output "ecs_service_security_groups_id" {
  value = tolist([aws_security_group.ecs_load_balancer_security_group.id])
}

output "subnets" {
  value = tolist([aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id])
}