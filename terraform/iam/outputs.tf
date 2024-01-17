output "bedrock_role" {
  value = aws_iam_role.bedrock.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_executor_role.arn
}