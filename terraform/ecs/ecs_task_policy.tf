# Generates an IAM policy document for the ECS task role
data "aws_iam_policy_document" "ecs_task_policy" {
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
  statement {
    sid       = 3
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::bedrock-qa-bucket-tf/*"]
  }
  statement {
    sid       = 4
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secrets_manager_arns
  }
}

# IAM policy for ECS task role
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "ecs_task_policy"
  description = "Allow ECS task to call bedrock and S3"
  policy      = data.aws_iam_policy_document.ecs_task_policy.json
}

# IAM role for ECS
resource "aws_iam_role" "ecs_task_role" {
  name = var.ecs_task_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Condition = {
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
    ]
  })
}

# Attach the policy to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_attachment" {
  policy_arn = aws_iam_policy.ecs_task_policy.arn
  role       = aws_iam_role.ecs_task_role.name
}