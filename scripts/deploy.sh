#!/bin/bash
set -e # Exit if any command fails

# This script is used to deploy the application

# Get region and account id using aws cli
AWS_REGION=$(aws configure get region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_ECR_REPOSITORY_NAME=ecs-repo # Replace with your ECR repository name
AWS_ECR_REPOSITORY_URL=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPOSITORY_NAME
TAG=$(git rev-parse HEAD) # Get current short commit hash

# Login to AWS ECR
echo "Logging in to AWS ECR..."
aws ecr get-login-password \
    --region $AWS_REGION | docker login \
    --username AWS \
    --password-stdin $AWS_ECR_REPOSITORY_URL

# Build the Docker image
echo "Building Docker image..."
docker build -t $AWS_ECR_REPOSITORY_NAME .

Check if the ECR repository exists
echo "Checking if ECR repository exists..."
if aws ecr describe-repositories \
    --repository-names $AWS_ECR_REPOSITORY_NAME \
    --region $AWS_REGION > /dev/null 2>&1; then
    echo "ECR repository exists, deleting..."
    aws ecr delete-repository \
    --repository-name $AWS_ECR_REPOSITORY_NAME \
    --region $AWS_REGION \
    --force
fi

# Create the ECR repository
echo "Creating ECR repository..."
aws ecr create-repository \
    --repository-name $AWS_ECR_REPOSITORY_NAME \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE \
    --no-cli-pager

# Tag the Docker image
echo "Tagging Docker image..."
docker tag $AWS_ECR_REPOSITORY_NAME:latest $AWS_ECR_REPOSITORY_URL:$TAG

# Push the Docker image
echo "Pushing Docker image..."
docker push $AWS_ECR_REPOSITORY_URL:$TAG

echo $AWS_ECR_REPOSITORY_URL:$TAG
