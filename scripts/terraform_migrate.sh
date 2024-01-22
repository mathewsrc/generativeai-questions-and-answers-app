#!/bin/bash

AWS_REGION=$(aws configure get region) && \
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) && \
cd terraform && terraform init  \
               -backend-config="region=$AWS_REGION" \
               -backend-config='assume_role={"role_arn":"arn:aws:iam::'$AWS_ACCOUNT_ID':role/terraform_state_role"}' \
			   -migrate-state && \
terraform refresh