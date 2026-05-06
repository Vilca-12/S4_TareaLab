#  API GATEWAY HTTP v2 
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

# STAGE 
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  # Configuracion de logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format          = jsonencode({
      requestId = "$context.requestId",
      ip        = "$context.identity.sourceIp",
      user      = "$context.identity.user",
      routeKey  = "$context.routeKey",
      status    = "$context.status"
    })
  }
}

#  LOG GROUP PARA API GW 
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 14
}

# INTEGRACION CON LAMBDA UPLOAD 
resource "aws_apigatewayv2_integration" "upload_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.upload.invoke_arn
  payload_format_version = "2.0"
}

#RUTA POST /upload 
resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_integration.id}"
}