# General variables
variable "region" {
  default     = "us-east-1"
  description = "The region you want to deploy the solution"
}

variable "name" {
  default     = "rag"
  description = "the name for resource"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  default     = "bedrock-question-answer"
}

variable "environment" {
  description = "The environment the bucket is used in"
  default     = "Dev"
}

variable "ecr_name" {
  description = "The name of ECR repository"
  default     = "bedrock/bedrock_qa"
}

variable "ecs_task_name" {
  description = "The ECS task definition name"
  default     = "bedrock-qa-task"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  default     = "bedrock-qa-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  default     = "bedrock-qa-service"
}

#variable "collection_name" {
#  description = "Name of the OpenSearch Serverless collection."
#  default     = "bedrock-qa-collection"
#}
