# Bedrock setup

![image](https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/assets/94936606/d11ebb04-c02a-4aec-b786-363ebcd3bf05)

#TODO: add image of models 

Bedrock foundation models policy
```json
{
    "Version": "2012-10-17",
    "Statement": [ 
        {
            "Sid": "VisualEditor",
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

IAM create role policy

```json{
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "Stmt1469200763880",
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
				"iam:DeleteRole",
				"iam:ListPolicyVersions",
				"iam:DeletePolicy",
				"iam:CreatePolicyVersion",
				"iam:DeletePolicyVersion",
				"kms:DescribeKey"
			],
			"Effect": "Allow",
			"Resource": "*"
		}
	]
}
```

S3 policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3ConsoleAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetAccountPublicAccessBlock",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation",
                "s3:GetBucketPolicyStatus",
                "s3:GetBucketPublicAccessBlock",
                "s3:ListAccessPoints",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": ["arn:aws:s3:::bedrock"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["arn:aws:s3:::bedrock/*"]
        }
    ]
}
```


![Policies](policies.png)