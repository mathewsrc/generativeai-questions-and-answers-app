resource "aws_s3_bucket" "s3-bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
  }
}


resource "aws_s3_object" "object" {
  for_each     = fileset("documents/*.pdf", "**")
  bucket       = aws_s3_bucket.s3-bucket.id
  key          = each.value
  source       = "documents/${each.value}"
  content_type = each.value
  etag         = filemd5("documents/${each.value}")
}
