data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_task_exec_role_policy" {
  statement {
    sid       = 1
    actions = ["sts:AssumeRole", "logs:CreateLogGroup"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
      sid       = 2
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_execution_role_name
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task_exec_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "bedrock" {
  statement {
    sid       = 1
    actions   = ["bedrock:InvokeModel", "bedrock:ListCustomModels", "bedrock:ListFoundationModels"]
    resources = ["arn:aws:bedrock:*::foundation-model/*"]
  }
  statement {
    sid       = 2
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "bedrock" {
  name   = var.bedrock_policy_name
  policy = data.aws_iam_policy_document.bedrock.json
}

resource "aws_iam_role" "bedrock" {
  name               = var.bedrock_role_name
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

resource "aws_iam_role_policy_attachment" "bedrock-role" {
  policy_arn = aws_iam_policy.bedrock.arn
  role       = aws_iam_role.bedrock.name
}
