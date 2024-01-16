data "aws_iam_policy_document" "terraform_state_policy" {
  statement {
    sid       = 1
    actions   = [ "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::terraform-bucket-state-tf/terraform.tfstate"]
  }
   statement {
    sid       = 2
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_state_policy" {
  name   = var.terraform_state_policy_name
  policy = data.aws_iam_policy_document.s3-terraform-state.json
}

resource "aws_iam_role" "terraform_state_role" {
  name               = var.terraform_state_role_name
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

resource "aws_iam_role_policy_attachment" "terraform_state_role" {
  policy_arn = aws_iam_policy.terraform_state_policy.arn
  role       = aws_iam_role.terraform_state_role.name
}