# Creates an encryption security policy
resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "encryption-policy"
  type        = "encryption"
  description = "encryption policy for ${var.collection_name}"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}"
        ],
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

# Creates a collection
resource "aws_opensearchserverless_collection" "collection" {
  name = var.collection_name

  depends_on = [aws_opensearchserverless_security_policy.encryption_policy]
}
