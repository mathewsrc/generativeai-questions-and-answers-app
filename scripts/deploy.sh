#!/bin/bash

# This script is used to deploy the application

AWS_REGION=us-east-1
AWS_ACCOUNT_ID=078090784717
AWS_ECR_REPOSITORY=bedrock-qa-rag-ecr-tf
AWS_ECR_REPOSITORY_URL=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$AWS_ECR_REPOSITORY

# Login to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ECR_REPOSITORY_URL

# Build the Docker image
docker build -t $AWS_ECR_REPOSITORY:latest .

# Tag the Docker image
docker tag $AWS_ECR_REPOSITORY:latest $AWS_ECR_REPOSITORY_URL:latest

# Push the Docker image
docker push $AWS_ECR_REPOSITORY_URL:latest
