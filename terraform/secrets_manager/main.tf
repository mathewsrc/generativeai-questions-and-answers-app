resource "aws_secretsmanager_secret" "qdrant_url" {
  name                           = var.qdrant_url_key
  description                    = "Qdrant URL Key"
  recovery_window_in_days        = 0     # Force deletion without recovery
  force_overwrite_replica_secret = false # Force overwrite a secret with the same name in the destination Region.
  tags = {
    Name        = "Qdrant URL"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret" "qdrant_api_key" {
  name                           = var.qdrant_api_key
  description                    = "Qdrant API Key"
  recovery_window_in_days        = 0     # Force deletion without recovery
  force_overwrite_replica_secret = false # Force overwrite a secret with the same name in the destination Region.
  tags = {
    Name        = "Qdrant API Key"
    Environment = var.environment
  }
}