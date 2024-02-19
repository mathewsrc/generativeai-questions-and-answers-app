variable "s3_bucket_id" {
  description = "The ID of the S3 bucket to which the Lambda function will be subscribed"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket to which the Lambda function will be subscribed"
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the Lambda function"
  default     = "create_vector_store"
  type        = string
}

variable "environment" {
  description = "The environment the bucket is used in [DEV, STAG, PROD]"
  validation {
    condition     = contains(["DEV", "STAG", "PROD"], var.environment)
    error_message = "Environment must be one of DEV, STAG, PROD"
  }
}

variable "application_name" {
  description = "Application name"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "lambda-layer-rag-bucket"
}

variable "s3_key" {
  description = "The key of the S3 object"
  type        = string
  default     = "lambda_layer.zip"
}

variable "layer_name" {
  description = "The name of the Lambda layer"
  type        = string
  default     = "lambda_layer"
}

variable "handler" {
  description = "The name of the handler"
  type        = string
  default     = "main.lambda_handler"
}

variable "memory_size" {
  description = "The amount of memory in MB that Lambda Function can use at runtime"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "The amount of time in seconds that Lambda Function has to run"
  type        = number
  # 10 minutes
  default = 600
}

variable "python_version" {
  description = "The Python version to use"
  type        = string
  default     = "python3.12"
}
variable "ecr_repository" {
  description = "The URL of the ECR repository"
  type        = string
  default     = "lambda-repo"

}