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