# <<< OpenSearch >>>

data "aws_iam_policy_document" "opensearch" {
  statement {
    sid    = "opensearch"
    effect = "Allow"
    actions = [
      "aoss:CreateSecurityPolicy",
      "aoss:CreateAccessPolicy",
      "aoss:ListCollections",
      "aoss:BatchGetCollection",
      "aoss:BatchGetVpcEndpoint",
      "aoss:CreateCollection",
      "aoss:DeleteAccessPolicy",
      "aoss:CreateSecurityConfig",
      "aoss:DeleteCollection",
      "aoss:DeleteSecurityConfig",
      "aoss:DeleteSecurityPolicy",
      "aoss:UpdateAccessPolicy",
      "aoss:UpdateCollection",
      "aoss:UpdateSecurityConfig",
      "aoss:UpdateSecurityPolicy",
      "aoss:ListVpcEndpoints",
      "aoss:CreateVpcEndpoint",
      "aoss:DeleteVpcEndpoint",
      "aoss:UpdateVpcEndpoint",
      "aoss:TagResource",
      "aoss:ListTagsForResource",
      "aoss:UntagResource"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ec2"
    effect = "Allow"
    actions = [
      "ec2:CreateVpcEndpoint",
      "ec2:CreateVpcEndpointConnectionNotification",
      "ec2:DeleteVpcEndpoints",
      "ec2:ModifyVpcEndpoint",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcEndpointConnections",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcEndpointServices",
      "ec2:DescribeVpcs",
      "ec2:CreateVpc",
      "ec2:CreateVpcEndpointServiceConfiguration",
      "ec2:DeleteVpc",
      "ec2:DeleteVpcEndpointConnectionNotifications",
      "ec2:DeleteVpcEndpointServiceConfigurations",
      "ec2:ModifyVpcAttribute",
      "ec2:ModifyVpcEndpointConnectionNotification"
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*",
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc/*",
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*"
    ]
  }

  statement {
    sid    = "iam"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:DeleteServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/observability.aoss.amazonaws.com/AWSServiceRoleForAmazonOpenSearchServerless"
    ]
  }
}

resource "aws_iam_policy" "opensearch" {
  name   = "opensearch_policy"
  policy = data.aws_iam_policy_document.opensearch.json
}