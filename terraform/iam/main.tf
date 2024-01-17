# <<< ECS >>>

# Get the current AWS account ID
data "aws_caller_identity" "current" {}


# Generates an IAM policy document in JSON format
data "aws_iam_policy_document" "ecs_task_executor_policy" {
  statement {
    sid     = 1
    actions = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup"]
    resources = [
    "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:bedrock:log-stream:*"]
  }
  statement {
    sid       = 2
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

# IAM policy for ECS task executor role
resource "aws_iam_policy" "ecs_task_executor_policy" {
  name        = var.ecs_policy_name
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
            "Action": "sts:AssumeRole"
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

# <<< Bedrock >>>

# Generates an IAM policy document in JSON format
data "aws_iam_policy_document" "bedrock" {
  statement {
    sid       = 1
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
  statement {
    sid       = 2
    actions   = ["bedrock:InvokeModel", "bedrock:ListCustomModels", "bedrock:ListFoundationModels"]
    resources = ["arn:aws:bedrock:*::foundation-model/*"]
  }
}

# IAM policy for Bedrock role
resource "aws_iam_policy" "bedrock" {
  name   = var.bedrock_policy_name
  policy = data.aws_iam_policy_document.bedrock.json
}

# IAM role for Bedrock
resource "aws_iam_role" "bedrock" {
  name               = var.bedrock_role_name
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  POLICY
}

# Attach the policy to the Bedrock role
resource "aws_iam_role_policy_attachment" "bedrock-role" {
  policy_arn = aws_iam_policy.bedrock.arn
  role       = aws_iam_role.bedrock.name
}
