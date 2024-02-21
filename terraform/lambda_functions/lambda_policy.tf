# Create an IAM policy document for the lambda
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "S3Access"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::*",
    ]
  }

  statement {
    sid       = "BedrockAccess"
    actions   = ["bedrock:InvokeModel", "bedrock:ListCustomModels", "bedrock:ListFoundationModels"]
    resources = ["arn:aws:bedrock:*::foundation-model/*"]
  }
}

# Create an IAM policy for the lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "IAM policy for lambda"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

# Create an IAM role for the lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the policy to the lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

