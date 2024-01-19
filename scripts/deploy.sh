#!/bin/bash

# This script is used to deploy the application

# Get region and account id using aws cli
AWS_REGION=$(aws configure get region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_ECR_REPOSITORY=bedrock-qa-rag-ecr-tf # Replace with your ECR repository name
AWS_ECR_REPOSITORY_URL=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPOSITORY
TAG=$(git rev-parse HEAD) # Get the short commit hash

# Login to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ECR_REPOSITORY_URL

# Build the Docker image
docker build -t $AWS_ECR_REPOSITORY . 

# Tag the Docker image
docker tag $AWS_ECR_REPOSITORY:latest $AWS_ECR_REPOSITORY_URL:$TAG

# Push the Docker image
docker push $AWS_ECR_REPOSITORY_URL:$TAG
