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

variable "ecs_security_group_name" {
  description = "The name of the ECS security group"
  default     = "bedrock-qa-rag-ecs-security-group-tf"
}

variable "load_balance_name" {
  description = "The name of Load Balance"
  default     = "bedrock-qa-rag-load-balance-tf"
}

variable "load_balancer_target_group_name" {
  description = "The name of Load balancer target group"
  default     = "bedrock-qa-rag-target-group-tf"
}



variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection."
  default     = "bedrock-qa-collection-tf"
}

variable "collection_type" {
  description = "The type of the OpenSearch Serverless collection."
  default     = "VECTORSEARCH"
}

variable "subnet_ids" {
  description = "The subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "The security group ids"
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "vpc_endpoint_name" {
  description = "The name of the VPC endpoint"
  default     = "opensearch-vpc-endpoint"
}

variable "vpc_endpoint_type" {
  description = "The type of the VPC endpoint"
  default     = "Interface"
}

variable "encryption_policy_name" {
  description = "The name of the encryption policy"
  default     = "opensearch-encryption-policy"
}

variable "security_policy_type" {
  description = "The encryption type"
  default     = "encryption"
}

variable "network_policy_name" {
  description = "The name of the network policy"
  default     = "opensearch-network-policy"
}

variable "network_policy_type" {
  description = "The type of the network policy"
  default     = "network"
}

variable "data_access_policy_name" {
  description = "The name of the data access policy"
  default     = "opensearch-data-access-policy"
}

variable "data_acess_policy_type" {
  description = "The type of the data access policy"
  default     = "data"
}
