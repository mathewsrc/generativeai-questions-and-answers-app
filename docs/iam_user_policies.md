# Creating a user in AWS IAM

You should create a user with restricted permissions for the purpose of recreating this project. AWS recommends the establishment of a user or role with only the essential permissions necessary, emphasizing this as a best practice for both security and overall safety.

Below are all policies needed for your new AWS user

## Policies

Please substitute the AWS region <YOUR-AWS-REGION> with the region applicable to your usage, should you be operating in a different region. Additionally, replace <YOUR-ACCOUNT-ID> with your specific account ID, which can be obtained by executing the command aws sts get-caller-identity

Bedrock

```terraform
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "bedrock",
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:ListCustomModels",
                "bedrock:ListFoundationModels"
            ],
            "Resource": "*"
        }
    ]
}
```

ECR (Elastic Container Repository)

```terraform
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ecr1",
            "Effect": "Allow",
            "Action": [
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
            ],
            "Resource": [
                "arn:aws:ecr:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:repository/*"
            ]
        },
        {
            "Sid": "ecr2",
            "Effect": "Allow",
            "Action": [
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
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

ECS (Elastic Container Service)

```terraform
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ecs1",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ec2:DeleteSubnet",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:CreateVpc",
                "ec2:RunInstances",
                "ec2:ModifyVpcAttribute",
                "ec2:DeleteVpc",
                "ec2:CreateSubnet",
                "ec2:ModifySubnetAttribute",
                "ec2:CreateDefaultSubnet"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ecs2",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "arn:aws:ec2:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:security-group/*"
        },
        {
            "Sid": "ecs3",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": [
                "arn:aws:ec2:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:subnet/*",
                "arn:aws:ec2:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:vpc/*"
            ]
        },
        {
            "Sid": "ecs4",
            "Effect": "Allow",
            "Action": [
                "ecs:DeregisterTaskDefinition",
                "ecs:RegisterTaskDefinition",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeClusters",
                "ecs:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ecs5",
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateCluster",
                "ecs:UpdateClusterSettings",
                "ecs:DeleteCluster",
                "ecs:CreateCluster"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ecs6",
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:CreateService",
                "ecs:DeleteService",
                "ecs:DescribeServices",
                "ecs:ListServices",
                "ecs:ListServicesByNamespace"
            ],
            "Resource": "arn:aws:ecs:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:service/*/*"
        },
        {
            "Sid": "ecs7",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeInstanceHealth"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ecs8",
            "Effect": "Allow",
            "Action": [
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
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:loadbalancer/app/*/*",
                "arn:aws:elasticloadbalancing:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:loadbalancer/net/*/*"
            ]
        },
        {
            "Sid": "ecs9",
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogGroups",
                "logs:FilterLogEvents",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ecs10",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateDefaultVpc",
                "ec2:CreateDefaultSubnet"
            ],
            "Resource": [
                "arn:aws:ec2:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:subnet/*",
                "arn:aws:ec2:<YOUR-AWS-REGION>:<YOUR-ACCOUNT-ID>:vpc/*"
            ]
        }
    ]
}
```

IAM 

```terraform
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "iam1",
            "Action": [
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
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Sid": "iam2",
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": [
                "arn:aws:iam::<YOUR-ACCOUNT-ID>:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing"
            ]
        },
        {
            "Sid": "iam3",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::<YOUR-ACCOUNT-ID>:role/terraform_state_role"
            ]
        }
    ]
}
```

S3 policy for Terraform state file

```terraform
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "terraformstate"
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::terraform-bucket-state-tf",
                "arn:aws:s3:::terraform-bucket-state-tf/*/*"
            ]
        }
    ]
}
```

S3 policy for documents

```terraform
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "bucket",
            "Effect": "Allow",
            "Action": [
                "s3:*Object",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetBucketPolicyStatus",
                "s3:ListBucket",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:ListAccessPoints"
            ],
            "Resource": "arn:aws:s3:::*"
        }
    ]
}
```

API Gateway
```terraform
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "apigateway:POST",
                "apigateway:GET",
                "apigateway:PATCH",
                "apigateway:DELETE"
                "apigateway:PUT"
            ],
            "Resource": [
                "arn:aws:apigateway:<YOUR-AWS-REGION>::/tags/*",
				"arn:aws:apigateway:<YOUR-AWS-REGION>::/restapis",
				"arn:aws:apigateway:<YOUR-AWS-REGION>::/restapis/*",
                "arn:aws:apigateway:<YOUR-AWS-REGION>::/vpclinks",
                "arn:aws:apigateway:<YOUR-AWS-REGION>::/vpclinks/*",
                "arn:aws:apigateway:<YOUR-AWS-REGION>::/tags/arn%3Aaws%3Aapigateway%3Aus-east-1%3A%3A%2Fvpclinks%2F*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DescribeLoadBalancers"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVpcEndpointServiceConfiguration",
                "ec2:DeleteVpcEndpointServiceConfigurations",
                "ec2:DescribeVpcEndpointServiceConfigurations",
                "ec2:ModifyVpcEndpointServicePermissions"
            ],
            "Resource": "*"
        },
        {
			"Sid": "Statement2",
			"Effect": "Allow",
			"Action": [
				"logs:TagResource",
				"logs:DescribeLogGroups",
				"logs:DescribeLogStreams",
				"logs:DescribeMetricFilters",
				"logs:DescribeQueries",
				"logs:DescribeQueryDefinitions",
				"logs:DescribeSubscriptionFilters",
				"logs:ListAnomalies",
				"logs:ListLogAnomalyDetectors",
				"logs:ListLogDeliveries",
				"logs:ListTagsForResource",
				"logs:ListTagsLogGroup",
				"logs:DescribeResourcePolicies",
				"logs:DescribeExportTasks",
				"logs:DescribeDestinations",
				"logs:DescribeDeliverySources",
				"logs:DescribeDeliveryDestinations",
				"logs:DescribeDeliveries",
				"logs:DescribeAccountPolicies",
				"logs:FilterLogEvents",
				"logs:GetLogAnomalyDetector",
				"logs:GetLogDelivery",
				"logs:GetLogEvents",
				"logs:GetLogGroupFields",
				"logs:GetLogRecord",
				"logs:GetQueryResults",
				"logs:CreateLogAnomalyDetector",
				"logs:CreateLogDelivery",
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:DeleteLogDelivery",
				"logs:DeleteLogGroup",
				"logs:DeleteLogStream",
				"logs:DeleteMetricFilter",
				"logs:DeleteQueryDefinition",
				"logs:UpdateLogDelivery",
				"logs:UpdateLogAnomalyDetector",
				"logs:UpdateAnomaly",
				"logs:TagLogGroup",
				"logs:UntagLogGroup",
				"logs:UntagResource",
				"logs:PutRetentionPolicy",
				"logs:DeleteRetentionPolicy"
			],
			"Resource": [
				"*"
			]
		}
    ]
}
```


Open Search Serveless
```terraform
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "aoss:APIAccessAll",
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
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Statement2",
            "Effect": "Allow",
            "Action": [
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
            ],
            "Resource": [
                "arn:aws:ec2:us-east-1:078090784717:vpc-endpoint/*",
                "arn:aws:ec2:us-east-1:078090784717:vpc/*",
                "arn:aws:ec2:us-east-1:078090784717:subnet/*",
                "arn:aws:ec2:us-east-1:078090784717:security-group/*"
            ]
        },
        {
            "Sid": "Statement3",
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole",
                "iam:DeleteServiceLinkedRole"
            ],
            "Resource": [
                "arn:aws:iam::078090784717:role/aws-service-role/observability.aoss.amazonaws.com/AWSServiceRoleForAmazonOpenSearchServerless"
            ]
        }
    ]
}
```