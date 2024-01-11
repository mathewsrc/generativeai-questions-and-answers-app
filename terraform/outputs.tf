output "bedrock_role" {
  value = aws_iam_role.bedrock.arn
}

output "s3_object_urls" {
  value = [for obj in aws_s3_object.pdf : aws_s3_object.pdf[obj].source]
}