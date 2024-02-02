output "bedrock_role_arn" {
  value = aws_iam_role.bedrock.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_executor_role.arn
}

output "ecs_aws_iam_role" {
  value = {}

  depends_on = [aws_iam_role.ecs_task_executor_role]
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}