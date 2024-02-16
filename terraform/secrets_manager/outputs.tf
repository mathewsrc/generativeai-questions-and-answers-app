output "secrets_manager_arns_ecs" {
  value = [aws_secretsmanager_secret.qdrant_url.arn, aws_secretsmanager_secret.qdrant_api_key.arn]
}