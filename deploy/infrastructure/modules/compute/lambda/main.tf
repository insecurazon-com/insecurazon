# Placeholder zip file for initial deployment
variable "module_depends_on" {
  description = "A list of modules that must be created before this one"
  type = list(any)
}

data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"
  
  source {
    content  = "exports.handler = async () => ({ statusCode: 200, body: 'Placeholder' });"
    filename = "main.js"
  }
}

resource "aws_iam_role" "lambda_exec" {
  depends_on = [ var.module_depends_on ]
  name = "${var.lambda_config.function_name}-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Lambda function
resource "aws_lambda_function" "nestjs_app" {
  depends_on = [ var.module_depends_on ]
  function_name = var.lambda_config.function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = var.lambda_config.handler
  runtime       = var.lambda_config.runtime
  timeout       = 30
  memory_size   = 512

  # Placeholder code - will be replaced by GitHub Actions
  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  vpc_config {
    subnet_ids = var.lambda_config.subnet_ids
    security_group_ids = [aws_security_group.lambda_security_group.id]
  }
}

# API Gateway v2
resource "aws_apigatewayv2_api" "main" {
  name          = var.lambda_config.api_gateway_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.nestjs_app.invoke_arn
}

resource "aws_apigatewayv2_route" "catch_all" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Add stage for API Gateway
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
    })
  }
}

# CloudWatch log group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.lambda_config.api_gateway_name}"
  retention_in_days = 7
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nestjs_app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Output the Lambda function name for GitHub Actions
output "lambda_function_name" {
  value = aws_lambda_function.nestjs_app.function_name
}

output "api_gateway_url" {
  value = aws_apigatewayv2_api.main.api_endpoint
}