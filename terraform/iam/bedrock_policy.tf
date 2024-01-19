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
  name   = "bedrock-policy-tf"
  policy = data.aws_iam_policy_document.bedrock.json
}