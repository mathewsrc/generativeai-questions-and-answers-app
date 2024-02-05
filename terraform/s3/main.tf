# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region
data "aws_region" "current" {}

# Create an S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
    Application = var.application_name
  }
}

# Create an S3 bucket object for each PDF file in the documents directory
resource "aws_s3_object" "object" {
  # Recursively look for pdf files inside documents/ 
  bucket   = aws_s3_bucket.bucket.id
  for_each = fileset("../documents/${var.subfolder}/", "**/*.pdf")
  key      = each.value
  source   = "../documents/${var.subfolder}/${each.value}"
  etag     = filemd5("../documents/${var.subfolder}/${each.value}")

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
    Application = var.application_name
  }

  depends_on = [
    aws_s3_bucket.bucket
  ]
}