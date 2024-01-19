# <<< ECR >>>

data "aws_iam_policy_document" "ecr" {
  statement {
    sid    = "ecr1"
    effect = "Allow"
    actions = [
      "ecr:TagResource",
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:PutImage",
      "ecr:UntagResource",
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart"
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }

  statement {
    sid    = "ecr2"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr" {
  name   = "ecr_policy"
  policy = data.aws_iam_policy_document.ecr.json
}

