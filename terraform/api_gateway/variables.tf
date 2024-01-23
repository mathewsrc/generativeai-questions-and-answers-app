variable "laod_balancer_arn"{
    description = "The ARN of the load balancer"
    type = string
}

variable "vpc_link_name" {
    description = "The name of the VPC link"
    default = "vpc-link"
    type = string
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