# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda" 
  output_path = "${path.module}/../../lambda_payload.zip"
}

data "external" "envs" {
  program = ["sh", "-c", <<-EOSCRIPT
    jq -n '{ "qdrant_url": $QDRANT_URL, "qdrant_api_key": $QDRANT_API_KEY }' \
      --arg QDRANT_URL "$(printenv QDRANT_URL)" \
      --arg QDRANT_API_KEY "$(printenv QDRANT_API_KEY)" \
  EOSCRIPT
  ]
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "func" {
  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.log_group,
  ]

  filename      = "lambda_payload.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.py" # Function entrypoint 
  runtime       = "python3.12"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      QDRANT_URL = "${data.external.envs.result.qdrant_url}"
      QDRANT_API_KEY = "${data.external.envs.result.qdrant_api_key}"
    }
  }

  tags = {
    Name = var.lambda_function_name
    Environment = var.environment
    Application = var.application_name
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "cnu/"
    filter_suffix       = "all_files_uploaded_marker.txt" # Workround to trigger to just call the lambda function once
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}