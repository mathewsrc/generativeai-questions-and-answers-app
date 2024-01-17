variable "region" {
  default     = "us-east-1"
  description = "The region of deploy"
}

variable "name" {
  default     = "bedrock-qa-rag"
  description = "The name for resource"
}

variable "environment" {
  description = "The environment the bucket is used in [DEV, STAG, PROD]"
  validation {
    condition     = contains(["DEV", "STAG", "PROD"], var.environment)
    error_message = "Environment must be one of DEV, STAG, PROD"
  }
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

variable "ecs_security_group_name" {
  description = "The name of the ECS security group"
  default     = "bedrock-qa-rag-ecs-security-group-tf"
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

variable "ecr_repository_url" {
  description = "The url of ECR repository"
}

variable "ecr_repository_name" {
  description = "The name of ECR repository"
}

variable "target_group_arn" {
  description = "The arn of target group"
}

variable "ecs_service_security_groups_id" {
  description = "The id of ECS service security group"
  type        = list(string)
}

variable "subnets" {
  description = "The subnets of ECS service"
  type        = list(string)
}

variable "ecs_task_execution_role_arn" {
  description = "The arn of ECS task execution role"
}