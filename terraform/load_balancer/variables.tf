variable "vpc_id" {
  description = "The id of VPC"
}

variable "public_subnets" {
  description = "VPC public subnets"
  type        = list(string)
}

variable "region" {
  description = "The region where the resources will be created"
}

variable "environment" {
  description = "The environment the bucket is used in [DEV, STAG, PROD]"
  validation {
    condition     = contains(["DEV", "STAG", "PROD"], var.environment)
    error_message = "Environment must be one of DEV, STAG, PROD"
  }
}

variable "container_port" {
  description = "The port the application is listening on"
}

variable "target_group_name" {
  default     = "bedrock-qa-rag-tg"
  description = "The name of the target group"
}

variable "nlb_name" {
  default     = "bedrock-qa-rag-nlb"
  description = "The name of the network load balancer"
}

variable "application_name" {
  default     = "bedrock-qa-rag"
  description = "Application name"
}