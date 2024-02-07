# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification

# Execute a Bash script to create the libraries package
resource "null_resource" "package_lambda" {
  provisioner "local-exec" {
    command     = "chmod +x ${path.module}/../../scripts/package_lambda.sh; ${path.module}/../../scripts/package_lambda.sh"
    interpreter = ["bash", "-c"]
  }
}

# Create a zip file from the libraries package
data "archive_file" "layer" {
  type        = "zip"
  output_path = "${path.module}/../../files/lambda_layer.zip"
  source_dir  = "${path.module}/temp"
  depends_on  = [null_resource.package_lambda]
}

# Create a zip file from the lambda functions
data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/../../files/lambda_payload.zip"
  source_dir  = "${path.module}/../../lambda/functions"
  excludes = [
    "${path.module}/../../lambda/__pycache__"
  ]

  depends_on = [null_resource.package_lambda]
}

# Create an S3 bucket to store the lambda layer
resource "aws_s3_bucket" "layer" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
    Application = var.application_name
  }
}

# Create an S3 object to store the lambda layer
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.layer.id
  key    = "lambda_layer.zip"
  source = data.archive_file.layer.output_path

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
    Application = var.application_name
  }

  depends_on = [
    aws_s3_bucket.layer
  ]
}

# Create an Lambda layer
resource "aws_lambda_layer_version" "lambda_layer" {
  s3_bucket   = aws_s3_bucket.layer.id
  s3_key      = aws_s3_object.object.id
  layer_name  = "lambda_layer"
  description = "Lambda layer for embedding documents"

  compatible_runtimes = ["python3.12"]
}

# Get the Qdrant URL and API key from the environment
data "external" "envs" {
  program = ["sh", "-c", <<-EOSCRIPT
    jq -n '{ "qdrant_url": $QDRANT_URL, "qdrant_api_key": $QDRANT_API_KEY }' \
      --arg QDRANT_URL "$(printenv QDRANT_URL)" \
      --arg QDRANT_API_KEY "$(printenv QDRANT_API_KEY)" \
  EOSCRIPT
  ]
}

# Create a Lambda Function
resource "aws_lambda_function" "func" {
  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_lambda_layer_version.lambda_layer,
  ]

  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = data.archive_file.lambda.output_path
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler" # module main.py and function lambda_handler
  runtime       = "python3.12"
  memory_size   = var.memory_size

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

# Allow the Lambda function to be invoked by the S3 bucket
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

# Create an S3 bucket notification
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