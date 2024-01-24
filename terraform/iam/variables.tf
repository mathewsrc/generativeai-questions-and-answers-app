variable "region" {
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

variable "ecs_execution_role_name" {
  description = "The name of ECS execution role"
  default     = "bedrock-qa-rag-ecs-execution-role-tf"
}

variable "bedrock_role_name" {
  description = "The name of bedrock role"
  default     = "bedrock-qa-rag-bedrock-role-tf"
}
