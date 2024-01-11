# General variables
variable "region" {
  default     = "us-east-1"
  description = "The region you want to deploy the solution"
}

variable "name" {
  default     = "rag"
  description = "the name for resource"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  default     = "bedrock-question-answer"
}

variable "environment" {
  description = "The environment the bucket is used in"
  default     = "Dev"
}