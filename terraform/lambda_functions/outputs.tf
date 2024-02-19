output "wait_for_lambda_deployment" {
  value = {}

  depends_on = [aws_s3_bucket_notification.bucket_notification]
}