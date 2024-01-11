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

```json
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
                "iam:DeletePolicy"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```


![Policies](policies.png)