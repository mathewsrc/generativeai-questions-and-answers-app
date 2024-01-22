
# <<< S3 >>>
data "aws_iam_policy_document" "s3_state" {
  statement {
    sid    = "bucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::terraform-bucket-state-tf",
    "arn:aws:s3:::terraform-bucket-state-tf/*/*"]
  }
}

resource "aws_iam_policy" "s3_state" {
  name   = "bucket-state-policy-tf"
  policy = data.aws_iam_policy_document.s3_state.json
}