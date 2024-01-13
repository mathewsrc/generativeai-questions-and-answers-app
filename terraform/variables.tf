variable "region" {
  default     = "us-east-1"
  description = "The region of deploy"
}

variable "name" {
  default     = "rag"
  description = "The name for resource"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  default     = "bedrock-question-answer-tf"
}

variable "environment" {
  description = "The environment the bucket is used in"
  default     = "Dev"
}

variable "ecr_name" {
  description = "The name of ECR repository"
  default     = "bedrock-qa-tf"
}

variable "ecs_task_family_name" {
  description = "The ECS task definition name"
  default     = "bedrock-qa-task-tf"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  default     = "bedrock-qa-cluster-tf"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  default     = "bedrock-qa-service-tf"
}

variable "ecs_execution_role_name" {
  description = "The name of ECS execution role"
  default     = "bedrock-qa-ecs-execution-role_tf"
}

variable "ecs_security_group_name" {
  description = "The name of the ECS security group"
  default     = "bedrock-qa-ecs-security-group-tf"
}

variable "load_balance_name" {
  description = "The name of Load Balance"
  default     = "bedrock-qa-load-balance-tf"
}

variable "load_balancer_target_group_name" {
  description = "The name of Load balancer target group"
  default     = "bedrock-qa-target-group-tf"
}

variable "container_name" {
  description = "The name of container"
  default     = "bedrock-qa-container-tf"
}


#variable "collection_name" {
#  description = "Name of the OpenSearch Serverless collection."
#  default     = "bedrock-qa-collection-tf"
#}
