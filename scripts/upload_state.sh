#!/bin/bash

# This script is used to upload the state file to the S3 bucket

# Set the variables
BUCKET_NAME="terraform-bucket-state-tf"
STATE_FILE="terraform/terraform.tfstate"
AWS_REGION=$(aws configure get region)

# Create the S3 bucket if it doesn't exist
aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION 

# Upload the state file to the S3 bucket
aws s3 cp $STATE_FILE s3://$BUCKET_NAME/state/