variable "region" {
  description = "The region of deploy"
}

variable "application_name" {
  default     = "bedrock-qa-rag"
  description = "Application name"
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
