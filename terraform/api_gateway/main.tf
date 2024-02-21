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
  api_id             = aws_apigatewayv2_api.example.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.lb_listener_arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.vpc_link.id
}

resource "aws_apigatewayv2_integration" "ask_integration" {
  api_id             = aws_apigatewayv2_api.example.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.lb_listener_arn
  integration_method = "POST"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.vpc_link.id
}

resource "aws_apigatewayv2_route" "root_route" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.root_integration.id}"
}

resource "aws_apigatewayv2_route" "ask_route" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "POST /ask"
  target    = "integrations/${aws_apigatewayv2_integration.ask_integration.id}"
}

resource "aws_cloudwatch_log_group" "apigateway" {
  name              = "/aws/apigateway/${var.application_name}/${var.api_name}"
  retention_in_days = 7
  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}

resource "aws_apigatewayv2_stage" "example" {
  api_id      = aws_apigatewayv2_api.example.id
  description = "Stage for HTTP API"
  name        = "$default" # The $default stage is a special stage that's automatically associated with new deployments.
  auto_deploy = true       # Whether updates to an API automatically trigger a new deployment.

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway.arn
    format = jsonencode({
      requestId = "$context.requestId",
      ip        = "$context.identity.sourceIp",
      user      = "$context.identity.user",
      caller    = "$context.identity.caller",
      request   = "$context.requestTime",
      status    = "$context.status",
      response  = "$context.responseLength"
    })
  }
  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}
