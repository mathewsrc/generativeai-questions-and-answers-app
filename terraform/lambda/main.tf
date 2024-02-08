resource "null_resource" "package_lambda" {
  provisioner "local-exec" {
    command     = "chmod +x ${path.module}/../../scripts/package_lambda.sh; ${path.module}/../../scripts/package_lambda.sh"
    interpreter = ["bash", "-c"]
  }
}

# Archive the Lambda function 
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/src"
  output_path = "${path.module}/../../lambda/lambda_payload.zip"
  depends_on  = [null_resource.package_lambda]
}

# Archive layer
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/temp"
  output_path = "${path.module}/../../lambda/lambda_layer.zip"

  depends_on = [null_resource.package_lambda]
}

# Create bucket
resource "aws_s3_bucket" "layers" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = "${var.bucket_name} Bucket"
    Environment = var.environment
    Application = var.application_name
  }
}

# Upload zip to S3
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.layers.id
  key    = var.s3_key
  source = data.archive_file.layer.output_path
  etag   = filemd5(data.archive_file.layer.output_path)

  depends_on = [null_resource.package_lambda]
}

# Create layer
resource "aws_lambda_layer_version" "layer" {
  s3_bucket           = aws_s3_bucket.layers.bucket
  s3_key              = aws_s3_object.object.key
  layer_name          = var.layer_name
  description         = "Lambda layer for Qdrant"
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
    aws_lambda_layer_version.layer,
  ]

  filename      = data.archive_file.lambda.output_path
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.handler # module.py and function name
  runtime       = "python3.12"
  memory_size   = var.memory_size
  timeout       = var.timeout
  package_type  = "Zip"

  layers = [aws_lambda_layer_version.layer.arn]

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
    filter_suffix       = ".pdf"
  }
  depends_on = [aws_lambda_permission.allow_bucket]
}