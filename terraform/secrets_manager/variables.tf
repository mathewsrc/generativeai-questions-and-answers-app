variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "qdrant_url_key" {
  description = "Qdrant URL Key"
  type        = string
  default     = "prod/qdrant_url"
}

variable "qdrant_api_key" {
  description = "Qdrant API Key"
  type        = string
  default     = "prod/qdrant_api_key"
}

variable "region" {
  description = "AWS Region"
  type        = string
}