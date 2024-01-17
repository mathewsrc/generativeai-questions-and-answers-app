output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "git_sha" {
  description = "The latest git commit SHA"
  value       = data.external.envs.result.sha
}
