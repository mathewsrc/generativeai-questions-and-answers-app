
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
  program = ["bash", "-c", <<-EOSCRIPT
    : "$${QDRANT_URL_AWS:?Missing environment variable QDRANT_URL_AWS}"
    : "$${QDRANT_API_KEY_AWS:?Missing environment variable QDRANT_API_KEY_AWS}"
    jq --arg QDRANT_URL_AWS "$(printenv QDRANT_URL_AWS)" \
       --arg QDRANT_API_KEY_AWS "$(printenv QDRANT_API_KEY_AWS)" \
       --arg SHA "$(git rev-parse HEAD)" \
       -n '{ "qdrant_url": $QDRANT_URL_AWS, 
             "qdrant_api_key": $QDRANT_API_KEY_AWS,
             "sha": $SHA}'
  EOSCRIPT
  ]
}

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