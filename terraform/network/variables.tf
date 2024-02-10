variable "region" {
  description = "The region of deploy"
}

variable "environment" {
  description = "The environment the bucket is used in [DEV, STAG, PROD]"
  validation {
    condition     = contains(["DEV", "STAG", "PROD"], var.environment)
    error_message = "Environment must be one of DEV, STAG, PROD"
  }
}

variable "security_group_name_lb" {
  description = "The name of the security group"
  default     = "bedrock-qa-rag-lb-sg-tf"
}

variable "security_group_name_ecs_tasks" {
  description = "The name of the security group"
  default     = "bedrock-qa-rag-ecs-tasks-sg-tf"
}

variable "container_port" {
  description = "The port where the Docker is exposed"
  default     = 80
}


variable "aws_vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for vpc"
}

variable "aws_public_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "List of CIDR blocks for the public subnets"
}

variable "aws_private_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  description = "List of CIDR blocks for the private subnets"
}

variable "application_name" {
  default     = "bedrock-qa-rag"
  description = "Application name"
}