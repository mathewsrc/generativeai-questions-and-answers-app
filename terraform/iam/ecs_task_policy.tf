# Generates an IAM policy document in JSON format
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
}

# IAM policy for ECS task role
resource "aws_iam_policy" "ecs_task_policy" {
  name   = "ecs_task_policy"
  description = "Allow ECS task to call bedrock and S3"
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}