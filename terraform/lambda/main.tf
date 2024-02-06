# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification


data "archive_file" "layer" {
  type        = "zip"
  output_path = "${path.module}/../../files/lambda_layer.zip"
  source_dir  = "${path.module}/../../lambda/package"
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/../../files/lambda_payload.zip"
  source_dir  = "${path.module}/../../lambda/functions"
  excludes = [
    "${path.module}/../../lambda/__pycache__"
  ]
}

# create a s3 bucket to store the lambda layer
resource "aws_s3_bucket" "layer" {
  bucket = var.bucket_name

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
    Application = var.application_name
  }
}

# upload the lambda layer to s3
resource "aws_s3_object" "object" {
  # Recursively look for pdf files inside documents/ 
  bucket = aws_s3_bucket.layer.id
  key    = "lambda_layer.zip"
  source = "${path.module}/../../files/lambda_layer.zip"

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
    Application = var.application_name
  }

  depends_on = [
    aws_s3_bucket.layer
  ]
}

resource "aws_lambda_layer_version" "lambda_layer" {
  #filename    = "${path.module}/../../files/lambda_layer.zip" # Error: Hit the 50MB limit
  s3_bucket   = aws_s3_bucket.layer.id
  s3_key      = aws_s3_object.object.id
  layer_name  = "lambda_layer"
  description = "Lambda layer for embedding documents"

  compatible_runtimes = ["python3.12"]
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
    aws_lambda_layer_version.lambda_layer,
    aws_cloudwatch_log_group.log_group,
  ]

  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/../../files/lambda_payload.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.py" # Function entrypoint 
  runtime       = "python3.12"
  memory_size   = 256

  layers = [aws_lambda_layer_version.lambda_layer.arn]

  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      QDRANT_URL     = "${data.external.envs.result.qdrant_url}"
      QDRANT_API_KEY = "${data.external.envs.result.qdrant_api_key}"
    }
  }

  tags = {
    Name        = var.lambda_function_name
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
    filter_suffix       = ".pdf"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}