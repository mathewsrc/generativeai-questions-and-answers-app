variable "region" {
  default     = "us-east-1"
  description = "The region of deploy"
}

variable "name" {
  default     = "bedrock-qa-rag"
  description = "The name for resource"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  default     = "$bedrock-qa-rag-bucket-tf"
}

variable "environment" {
  description = "The environment the bucket is used in [DEV, STAG, PROD]"
  validation {
    condition     = contains(["DEV", "STAG", "PROD"], var.environment)
    error_message = "Environment must be one of DEV, STAG, PROD"
  }
}

variable "ecr_name" {
  description = "The name of ECR repository"
  default     = "bedrock-qa-rag-ecr-tf"
}

variable "ecs_task_family_name" {
  description = "The ECS task definition name"
  default     = "bedrock-qa-rag-task-tf"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  default     = "bedrock-qa-rag-cluster-tf"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  default     = "bedrock-qa-rag-service-tf"
}

variable "ecs_execution_role_name" {
  description = "The name of ECS execution role"
  default     = "bedrock-qa-rag-ecs-execution-role_tf"
}

variable "ecs_security_group_name" {
  description = "The name of the ECS security group"
  default     = "bedrock-qa-rag-ecs-security-group-tf"
}

variable "load_balance_name" {
  description = "The name of Load Balance"
  default     = "bedrock-qa-rag-load-balance-tf"
}

variable "load_balancer_target_group_name" {
  description = "The name of Load balancer target group"
  default     = "bedrock-qa-rag-target-group-tf"
}


variable "container_name" {
  description = "The name of container"
  default     = "bedrock-qa-rag-container-tf"
}

variable "container_port" {
  description = "The port of container"
  default     = 80
  type        = number
}

variable "cpu" {
  description = "The cpu of container"
  default     = 256
  type        = number
}

variable "memory" {
  description = "The memory of container"
  default     = 512
  type        = number
}


#variable "collection_name" {
#  description = "Name of the OpenSearch Serverless collection."
#  default     = "bedrock-qa-collection-tf"
#}
