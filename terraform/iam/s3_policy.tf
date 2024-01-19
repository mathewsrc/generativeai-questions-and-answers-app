# <<< S3 >>>

data "aws_iam_policy_document" "s3" {
  statement {
    sid    = "bucket"
    effect = "Allow"
    actions = [
      "s3:*Object",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketPolicyStatus",
      "s3:ListBucket",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetAccountPublicAccessBlock",
      "s3:ListAllMyBuckets",
      "s3:ListAccessPoints"
    ]
    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_policy" "s3" {
  name   = "bucket-documents-policy-tf"
  policy = data.aws_iam_policy_document.s3.json
}