# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region
data "aws_region" "current" {}

# IAM role for Bedrock
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

# <<< IAM role for ECS task executor >>>

resource "aws_iam_role" "ecs_task_executor_role" {
  name               = var.ecs_execution_role_name
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
              "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            "Condition": {
              "ArnLike": {
                "aws:SourceArn": "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
            }
        }
    ]
}
  POLICY
}

# Attach the policy to the ECS task executor role
resource "aws_iam_role_policy_attachment" "ecs_task_executor_attachment" {
  policy_arn = aws_iam_policy.ecs_task_executor_policy.arn
  role       = aws_iam_role.ecs_task_executor_role.name
}

# IAM role for ECS
resource "aws_iam_role" "ecs_task_role" {
  name =  var.ecs_task_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Condition = {
          "ArnLike":{
            "aws:SourceArn":"arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
    ]
  })
}

# Attach the policy to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_attachment" {
  policy_arn = aws_iam_policy.ecs_task_policy.arn
  role       = aws_iam_role.ecs_task_role.name
}

# resource "aws_iam_role_policy_attachment" "bedrock-ecs" {
#   policy_arn = aws_iam_policy.ecs.arn
#   role       = aws_iam_role.bedrock.name
# }

# resource "aws_iam_role_policy_attachment" "bedrock-iam" {
#   policy_arn = aws_iam_policy.iam.arn
#   role       = aws_iam_role.bedrock.name
# }

# resource "aws_iam_role_policy_attachment" "bedrock-s3" {
#   policy_arn = aws_iam_policy.s3.arn
#   role       = aws_iam_role.bedrock.name
# }

# resource "aws_iam_role_policy_attachment" "bedrock-opensearch" {
#   policy_arn = aws_iam_policy.opensearch.arn
#   role       = aws_iam_role.bedrock.name
# }

# resource "aws_iam_role_policy_attachment" "bedrock-ecr" {
#   policy_arn = aws_iam_policy.ecr.arn
#   role       = aws_iam_role.bedrock.name
# }

# resource "aws_iam_role_policy_attachment" "bedrock-s3-state" {
#   policy_arn = aws_iam_policy.s3_state.arn
#   role       = aws_iam_role.bedrock.name
# }

# resource "aws_iam_role_policy_attachment" "bedrock-role" {
#   policy_arn = aws_iam_policy.bedrock.arn
#   role       = aws_iam_role.bedrock.name
# }