resource "aws_apigatewayv2_api" "example" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "Example HTTP API"
  version       = "1.0"

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}

resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = var.vpc_link_name
  security_group_ids = var.security_group_ids
  subnet_ids         = var.subnet_ids
}

resource "aws_apigatewayv2_integration" "root_integration" {
  api_id               = aws_apigatewayv2_api.example.id
  integration_type     = "HTTP_PROXY"
  integration_uri      = var.lb_listener_arn
  integration_method   = "GET"
  connection_type      = "VPC_LINK"
  connection_id        = aws_apigatewayv2_vpc_link.vpc_link.id
  timeout_milliseconds = var.api_timeout_milliseconds
}

resource "aws_apigatewayv2_integration" "ask_integration" {
  api_id               = aws_apigatewayv2_api.example.id
  integration_type     = "HTTP_PROXY"
  integration_uri      = var.lb_listener_arn
  integration_method   = "POST"
  connection_type      = "VPC_LINK"
  connection_id        = aws_apigatewayv2_vpc_link.vpc_link.id
  timeout_milliseconds = var.api_timeout_milliseconds
}

resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.root_integration.id}"
}

resource "aws_apigatewayv2_route" "ask_route" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "POST /ask"
  target    = "integrations/${aws_apigatewayv2_integration.ask_integration.id}"
}

resource "aws_apigatewayv2_deployment" "example" {
  api_id      = aws_apigatewayv2_api.example.id
  description = "Example deployment"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_apigatewayv2_route.root_route,
    aws_apigatewayv2_route.ask_route,
    aws_apigatewayv2_integration.root_integration,
    aws_apigatewayv2_integration.ask_integration
  ]
}

resource "aws_apigatewayv2_stage" "example" {
  depends_on = [
    aws_apigatewayv2_deployment.example
  ]
  api_id        = aws_apigatewayv2_api.example.id
  description   = "Example stage"
  name          = "example-stage"
  deployment_id = aws_apigatewayv2_deployment.example.id
  auto_deploy   = false # Whether updates to an API automatically trigger a new deployment.

  route_settings {
    route_key              = aws_apigatewayv2_route.ask_route.route_key
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  default_route_settings {
    detailed_metrics_enabled = true
    logging_level            = "INFO"
  }

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}
