resource "aws_s3_bucket" "bedrock" {
  bucket = var.bucket_name

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_object" "bedrock-pdf" {
  for_each = fileset("./documents/", "**")
  bucket = var.bucket_name
  key = each.value
  source = "./documents/${each.value}"
  etag = filemd5("./documents/${each.value}")
}