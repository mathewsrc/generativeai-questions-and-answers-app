variable "region" {
  description = "The region of deploy"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  default     = "$bedrock-qa-rag-bucket-tf"
}

variable "subfolder" {
  description = "The name of the S3 bucket"
}

variable "environment" {
  description = "The environment the bucket is used in [DEV, STAG, PROD]"
  validation {
    condition     = contains(["DEV", "STAG", "PROD"], var.environment)
    error_message = "Environment must be one of DEV, STAG, PROD"
  }
}

variable "application_name" {
  default     = "bedrock-qa-rag"
  description = "Application name"
}