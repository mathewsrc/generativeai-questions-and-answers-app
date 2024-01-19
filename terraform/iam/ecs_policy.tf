# <<< ECS >>>

data "aws_iam_policy_document" "ecs" {
  statement {
    sid    = "ecs1"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:DeleteSubnet",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:RunInstances",
      "ec2:ModifyVpcAttribute",
      "ec2:DeleteVpc",
      "ec2:CreateSubnet",
      "ec2:CreateDefaultSubnet",
      "ec2:ModifySubnetAttribute"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ecs2"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:DeleteSecurityGroup"
    ]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*"]
  }

  statement {
    sid     = "ecs3"
    effect  = "Allow"
    actions = ["ec2:CreateTags"]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/*"
    ]
  }

  statement {
    sid    = "ecs4"
    effect = "Allow"
    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeClusters",
      "ecs:ListClusters"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ecs5"
    effect = "Allow"
    actions = [
      "ecs:UpdateCluster",
      "ecs:UpdateClusterSettings",
      "ecs:DeleteCluster",
      "ecs:CreateCluster"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ecs6"
    effect = "Allow"
    actions = [

      "ecs:UpdateService",
      "ecs:CreateService",
      "ecs:DeleteService",
      "ecs:DescribeServices",
      "ecs:ListServices",
      "ecs:ListServicesByNamespace"
    ]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/*/*"]
  }

  statement {
    sid    = "ecs7"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeInstanceHealth"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ecs"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:DeleteListener"
    ]
    resources = ["arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/*/*",
    "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:listener/app/*/*/*"]
  }

  statement {
    sid    = "ecs9"
    effect = "Allow"
    actions = [

      "logs:DescribeLogGroups",
      "logs:FilterLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ecs10"
    effect = "Allow"
    actions = [

      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup"
    ]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*",
    "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/*"]
  }
}

resource "aws_iam_policy" "ecs" {
  name   = "ecs-policy-tf"
  policy = data.aws_iam_policy_document.ecs.json
}
