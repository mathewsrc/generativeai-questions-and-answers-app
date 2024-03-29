
# Create a secret for Qdrant URL and API Key, so ECS can access it
resource "aws_secretsmanager_secret" "qdrant_url" {
  name                           = var.qdrant_url_key
  description                    = "Qdrant URL Key"
  recovery_window_in_days        = 0    # Force deletion without recovery
  force_overwrite_replica_secret = true # Force overwrite a secret with the same name in the destination Region.
  tags = {
    Name        = "Qdrant URL"
    Environment = var.environment
    Application = var.application_name
  }
}

# Create a secret for Qdrant API Key, so ECS can access it
resource "aws_secretsmanager_secret" "qdrant_api_key" {
  name                           = var.qdrant_api_key
  description                    = "Qdrant API Key"
  recovery_window_in_days        = 0    # Force deletion without recovery
  force_overwrite_replica_secret = true # Force overwrite a secret with the same name in the destination Region.
  tags = {
    Name        = "Qdrant API Key"
    Environment = var.environment
    Application = var.application_name
  }
}

# Get Enviroment variable from the local machine
data "external" "envs" {
  depends_on = [aws_secretsmanager_secret.qdrant_api_key, aws_secretsmanager_secret.qdrant_url]
  program = ["bash", "-c", <<-EOSCRIPT
    : "$${QDRANT_URL:?Missing environment variable QDRANT_URL}"
    : "$${QDRANT_API_KEY:?Missing environment variable QDRANT_API_KEY}"
    jq --arg QDRANT_URL "$(printenv QDRANT_URL)" \
       --arg QDRANT_API_KEY "$(printenv QDRANT_API_KEY)" \
       -n '{ "qdrant_url": $QDRANT_URL, 
             "qdrant_api_key": $QDRANT_API_KEY}'
  EOSCRIPT
  ]
}

# Upload the secrets to AWS Secrets Manager
resource "null_resource" "upload_secrets" {
  depends_on = [data.external.envs]
  provisioner "local-exec" {
    command     = <<EOF
      aws secretsmanager put-secret-value --secret-id prod/qdrant_url --secret-string ${data.external.envs.result.qdrant_url}
      aws secretsmanager put-secret-value --secret-id prod/qdrant_api_key --secret-string ${data.external.envs.result.qdrant_api_key}
    EOF
    interpreter = ["bash", "-c"]
  }
}