variable "vpc_link_name" {
  description = "The name of the VPC link"
  default     = "vpc-link"
  type        = string
}

variable "api_name" {
  description = "The name of the API"
  default     = "competition-notices-api"
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
  default     = 100
  type        = number
}

variable "quota_offset" {
  description = "Number of requests to subtract from the given limit.  "
  default     = 12
  type        = number
}

variable "burst_limit" {
  description = "The maximum rate limit over a time ranging from one to a few seconds"
  default     = 500 # Default value is 5.000 requests per second
  type        = number
}

variable "rate_limit" {
  description = "The API request steady-state rate limit."
  default     = 1000 # Default value is 10.000 requests per second
  type        = number
}

variable "application_name" {
  description = "Application name"
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

variable "lb_arn" {
  type        = string
  description = "The ARN of the internal NLB"
}

variable "lb_dns_name" {
  type        = string
  description = "The DNS name of the internal NLB"
}

variable "api_timeout_milliseconds" {
  description = "The timeout for the API (25000=25s)"
  default     = 25000
  type        = number
}

variable "subnet_ids" {
  description = "The subnet IDs for the VPC link"
  type        = list(string)
}

variable "security_group_ids" {
  description = "The security group IDs for the VPC link"
  type        = list(string)
}

variable "throttling_burst_limit" {
  description = "The maximum rate limit over a time ranging from one to a few seconds"
  default     = 500 # Default value is 5.000 requests per second
  type        = number
}

variable "throttling_rate_limit" {
  description = "The API request steady-state rate limit."
  default     = 1000 # Default value is 10.000 requests per second
  type        = number
}

variable "lb_listener_arn" {
  type        = string
  description = "The ARN of the load balance listener"
}