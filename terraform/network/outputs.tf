output "ecs_tasks_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "load_balancer_security_group_id" {
  value = aws_security_group.lb.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

output "private_subnets" {
  value = aws_subnet.private_subnets.*.id
}