# <<< IAM >>>

data "aws_iam_policy_document" "iam" {
  statement {
    sid    = "iam1"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:CreatePolicy",
      "iam:TagRole",
      "iam:TagPolicy",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:GetPolicy",
      "iam:ListInstanceProfilesForRole",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:DeleteRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:ListInstanceProfiles",
      "iam:ListRoles",
      "iam:PassRole",
      "iam:DetachRolePolicy"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "iam2"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing"]
  }

  statement {
    sid       = "iam3"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform_state_role"]
  }
}

resource "aws_iam_policy" "iam" {
  name   = "iam_policy"
  policy = data.aws_iam_policy_document.iam.json
}