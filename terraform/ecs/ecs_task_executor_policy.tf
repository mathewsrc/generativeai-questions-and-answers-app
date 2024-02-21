
# Generates an IAM policy document for the ECS task executor role
data "aws_iam_policy_document" "ecs_task_executor_policy" {
  statement {
    sid = 1
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
    "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
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

# IAM role for ECS task executor
resource "aws_iam_role" "ecs_task_executor_role" {
  name               = var.ecs_execution_role_name
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
              "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
              "ArnLike": {
                "aws:SourceArn": "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
              }
            }
        }
    ]
}
POLICY
}

# Attach the policy to the ECS task executor role
resource "aws_iam_role_policy_attachment" "ecs_task_executor_attachment" {
  policy_arn = aws_iam_policy.ecs_task_executor_policy.arn
  role       = aws_iam_role.ecs_task_executor_role.name
}
