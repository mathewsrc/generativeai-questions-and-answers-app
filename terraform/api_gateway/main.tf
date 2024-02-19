# Create a VPC Link from the API Gateway to the Load Balancer
resource "aws_api_gateway_vpc_link" "vpc_link" {
  name        = var.vpc_link_name
  description = "VPC link for API Gateway"
  target_arns = [var.lb_arn]
  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}

# Create a API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "API Gateway for REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Resource for GET /
# resource "aws_api_gateway_resource" "root_resource" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   parent_id   = aws_api_gateway_rest_api.api.root_resource_id
#   path_part   = "{proxy+}"
# }

# Method for GET /
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
  # request_parameters = {
  #   "method.request.path.proxy" = true
  # }
}

# Resource for POST /ask
resource "aws_api_gateway_resource" "ask_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "ask"
}

# Resource for POST /ask
resource "aws_api_gateway_method" "ask_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.ask_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration for GET /
resource "aws_api_gateway_integration" "root_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  #resource_id = aws_api_gateway_resource.root_resource.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${var.lb_dns_name}/"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
  # request_parameters = {
  #   "integration.request.path.proxy" = "method.request.path.proxy"
  # }
}

# Integration for POST /ask
resource "aws_api_gateway_integration" "ask_post_integration" {

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.ask_resource.id
  http_method = aws_api_gateway_method.ask_post.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "http://${var.lb_dns_name}/ask"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
}

# Create a API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.ask_post_integration,
    aws_api_gateway_integration.root_get_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  description = "Deployment for the dev stage"

  lifecycle {
    create_before_destroy = true # Without enabling create_before_destroy, API Gateway can return errors such as BadRequestException:
  }
}

# Create a API Gateway Stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.api_stage_name

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}

# resource "aws_api_gateway_method_settings" "all" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   stage_name  = aws_api_gateway_stage.api_stage.stage_name
#   method_path = "*/*" # This is the method path for all methods in the API

#   settings {
#     metrics_enabled = true
#     logging_level   = "INFO"
#   }
# }

# resource "aws_cloudwatch_log_group" "log_group" {
#   name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${var.api_stage_name}"
#   retention_in_days = var.logs_retantion_in_days

#   tags = {
#     Name        = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${var.api_stage_name}"
#     Environment = var.environment
#   }
# }

# Create a API Gateway Usage Plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name        = var.usage_plan_name
  description = "QA Usage Plan"

  quota_settings {
    limit  = var.quota_limit  # Maximum number of requests that can be made in a given time period.
    offset = var.quota_offset # Number of requests to subtract from the given limit.   
    period = var.period       # Time period in which the limit applies. Valid values are "DAY", "WEEK" or "MONTH".
  }

  throttle_settings {
    burst_limit = var.burst_limit # The maximum rate limit over a time ranging from one to a few seconds
    rate_limit  = var.rate_limit  # The API request steady-state rate limit.
  }

  tags = {
    Name        = var.usage_plan_name
    Environment = var.environment
    Application = var.application_name
  }
}