#!/bin/bash

# This script is used to deploy the application

# Get region and account id using aws cli
AWS_REGION=$(aws configure get region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_ECR_REPOSITORY_NAME=lambda-repo # Replace with your ECR repository name
AWS_ECR_REPOSITORY_URL=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPOSITORY_NAME
TAG=$(git rev-parse HEAD) # Get the short commit hash

# Login to AWS ECR
aws ecr get-login-password \
    --region $AWS_REGION | docker login \
    --username AWS \
    --password-stdin $AWS_ECR_REPOSITORY_URL

# Build the Docker image
docker build -t $AWS_ECR_REPOSITORY_NAME -f lambda/Dockerfile .

# Check if the ECR repository exists
aws ecr describe-repositories \
    --repository-names $AWS_ECR_REPOSITORY_NAME \
    --region $AWS_REGION > /dev/null 2>&1

    # If the repository exists, delete it
    if [ $? -eq 0 ]; then
        aws ecr delete-repository \
            --repository-name $AWS_ECR_REPOSITORY_NAME \
            --region $AWS_REGION \
            --force
    fi
    
# Create the ECR repository if it doesn't exist
aws ecr create-repository \
    --repository-name $AWS_ECR_REPOSITORY_NAME \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE

# Tag the Docker image
docker tag $AWS_ECR_REPOSITORY_NAME:latest $AWS_ECR_REPOSITORY_URL:$TAG

# Push the Docker image
docker push $AWS_ECR_REPOSITORY_URL:$TAG

export LAMBDA_ECR_REPOSITORY_URL=$AWS_ECR_REPOSITORY_URL:$TAG
