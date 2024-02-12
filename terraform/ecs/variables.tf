variable "region" {
  description = "The region of deploy"
}

variable "application_name" {
  description = "Application name"
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

variable "nlb_target_group_arn" {
  description = "The arn of target group"
}

variable "logs_group_name" {
  description = "The name of the logs group"
  default     = "bedrock"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  default     = "bedrock-qa-rag-cluster-tf"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  default     = "bedrock-qa-rag-service-tf"
}

variable "container_port" {
  description = "The port of container"
  type        = number
}

variable "cpu" {
  description = "The cpu of container"
  default     = 256
  type        = number
}

variable "memory" {
  description = "The memory of container"
  default     = 1024
  type        = number
}

variable "ecr_repository_url" {
  description = "The url of ECR repository"
}

variable "ecr_repository_name" {
  description = "The name of ECR repository"
}

variable "ecs_tasks_security_group_id" {
  description = "The security group ids"
  type        = list(string)
}

variable "private_subnets" {
  description = "VPC private subnets"
  type        = list(string)
}

variable "vpc_id" {
  description = "The id of VPC"
  type        = string
}

variable "ecs_execution_role_name" {
  description = "The name of ECS execution role"
  default     = "bedrock-qa-rag-ecs-execution-role-tf"
}

variable "ecs_task_role_name" {
  description = "The name of ECS task role"
  default     = "bedrock-qa-rag-ecs-task-role-tf"
}