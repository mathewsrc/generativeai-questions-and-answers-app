variable "vpc_link_name" {
  description = "The name of the VPC link"
  default     = "vpc-link"
  type        = string
}

variable "api_name" {
  description = "The name of the API"
  default     = "bedrock-qa-api"
  type        = string
}

variable "api_stage_name" {
  description = "The name of the API stage"
  default     = "prod"
  type        = string
}

variable "logs_retantion_in_days" {
  description = "The number of days to retain the logs"
  default     = 7
  type        = number
}

variable "usage_plan_name" {
  description = "The name of the usage plan"
  default     = "qa-usage-plan"
  type        = string
}

variable "period" {
  description = "The period of the usage plan"
  default     = "WEEK"
  type        = string
}

variable "quota_limit" {
  description = "Maximum number of requests that can be made in a given time period."
  default     = 20
  type        = number
}

variable "quota_offset" {
  description = "Number of requests to subtract from the given limit.  "
  default     = 2
  type        = number
}

variable "burst_limit" {
  description = "The maximum rate limit over a time ranging from one to a few seconds"
  default     = 5
  type        = number
}

variable "rate_limit" {
  description = "The API request steady-state rate limit."
  default     = 10
  type        = number
}

variable "name" {
  default     = "bedrock-qa-rag"
  description = "The name for resource"
}

variable "region" {
  default     = "us-east-1"
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

variable "nlb_arn" {
  type        = string
  description = "The ARN of the internal NLB"
}

variable "nlb_dns_name" {
  type        = string
  description = "The DNS name of the internal NLB"
}