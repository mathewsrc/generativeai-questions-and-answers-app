resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_object" "object" {
  # Recursively look for pdf files inside documents/ 
  bucket   = aws_s3_bucket.bucket.id
  for_each = fileset("../documents/", "**/*.pdf")
  key      = each.value
  source   = "../documents/${each.value}"
  etag     = filemd5("../documents/${each.value}")
  depends_on = [
    aws_s3_bucket.bucket
  ]
}