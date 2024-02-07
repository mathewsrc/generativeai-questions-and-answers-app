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
  default     = "bedrock-qa-rag"
  description = "Application name"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "lambda-layer-rag-bucket"
}

variable "output_layer_path" {
  description = "The path to the output layer"
  type        = string
  default     = "/files/lambda_layer.zip"
}

variable "output_lambda_path" {
  description = "The path to the output lambda"
  type        = string
  default     = "/files/lambda_payload.zip"
}

variable "memory_size" {
  description = "The amount of memory in MB that Lambda Function can use at runtime"
  type        = number
  default     = 256
}