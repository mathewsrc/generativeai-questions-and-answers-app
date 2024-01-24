variable "region" {
  description = "The region of deploy"
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

variable "number_of_private_subnets" {
  type        = number
  default     = 2
  description = "The number of private subnets in a VPC."
}

variable "number_of_public_subnets" {
  type        = number
  default     = 2
  description = "The number of public subnets in a VPC."
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
