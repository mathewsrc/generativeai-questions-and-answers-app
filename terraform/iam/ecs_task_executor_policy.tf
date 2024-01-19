
# Generates an IAM policy document in JSON format
data "aws_iam_policy_document" "ecs_task_executor_policy" {
  statement {
    sid = 1
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    "logs:CreateLogGroup"]
    resources = [
    "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:bedrock:log-stream:*"]
  }
  statement {
    sid = 2
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

# IAM policy for ECS task executor role
resource "aws_iam_policy" "ecs_task_executor_policy" {
  name        = "ecs-task-executor-policy-tf"
  description = "Policy for ECS task executor role"

  policy = data.aws_iam_policy_document.ecs_task_executor_policy.json
}

