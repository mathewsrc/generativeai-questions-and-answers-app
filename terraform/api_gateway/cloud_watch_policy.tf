# Get current account id
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

# Generates an IAM policy document 
data "aws_iam_policy_document" "cloudwatch" {
  statement {
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:PutResourcePolicy",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:CreateLogGroup",
      "logs:DescribeResourcePolicies",
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries"
    ]
    resources = ["*"]
  }
}

# IAM policy 
resource "aws_iam_policy" "cloudwatch" {
  name        = "cloudwatch_policy"
  description = "Allow API Gateway to write CloudWatch logs"
  policy      = data.aws_iam_policy_document.cloudwatch.json
}

# Generates an IAM policy document for the IAM role
data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

# IAM role 
resource "aws_iam_role" "cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  policy_arn = aws_iam_policy.cloudwatch.arn
  role       = aws_iam_role.cloudwatch.name
}