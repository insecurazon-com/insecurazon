# Current AWS Region
data "aws_region" "current" {} 

# CloudWatch Logs group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 14
}
