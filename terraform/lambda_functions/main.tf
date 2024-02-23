# Get current AWS region
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get the Qdrant URL and API key from the environment
data "external" "envs" {
  program = ["bash", "-c", <<-EOSCRIPT
    : "$${QDRANT_URL:?Missing environment variable QDRANT_URL}"
    : "$${QDRANT_API_KEY:?Missing environment variable QDRANT_API_KEY}"
    jq --arg QDRANT_URL "$(printenv QDRANT_URL)" \
       --arg QDRANT_API_KEY "$(printenv QDRANT_API_KEY)" \
       --arg SHA "$(git rev-parse HEAD)" \
       -n '{ "qdrant_url": $QDRANT_URL, 
             "qdrant_api_key": $QDRANT_API_KEY,
             "sha": $SHA}'
  EOSCRIPT
  ]
}

# Create a Lambda Function
resource "aws_lambda_function" "func" {
  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    #aws_lambda_layer_version.layer,
  ]
  role          = aws_iam_role.lambda_role.arn
  image_uri     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.ecr_repository}:${data.external.envs.result.sha}"
  function_name = var.lambda_function_name
  description   = "Converts PDFs to embeddings and stores them in Qdrant Cloud"
  #filename      = data.archive_file.lambda.output_path [Not required for Image type]
  #handler       = var.handler # module.py and function name [Not required for Image type]
  #runtime       = var.python_version [Not required for Image type]
  #layers = [aws_lambda_layer_version.layer.arn] [Not required for Image type]
  memory_size   = var.memory_size
  timeout       = var.timeout
  package_type  = "Image"
  architectures = ["x86_64"]


  environment {
    variables = {
      QDRANT_URL     = "${data.external.envs.result.qdrant_url}"
      QDRANT_API_KEY = "${data.external.envs.result.qdrant_api_key}"
      BUCKET_NAME    = var.s3_bucket_id
      REGION         = data.aws_region.current.name
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