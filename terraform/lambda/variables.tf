variable "s3_bucket_id" {
  description = "The ID of the S3 bucket to which the Lambda function will be subscribed"
  type = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket to which the Lambda function will be subscribed"
  type = string
}

variable "lambda_function_name" {
    description = "The name of the Lambda function"
    default = "create_vector_store"
    type = string
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