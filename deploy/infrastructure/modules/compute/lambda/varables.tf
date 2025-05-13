variable "lambda_config" {
  description = "Configuration for the Lambda function"
  type = object({
    function_name = string
    handler = string
    runtime = string
    vpc_id = string
    subnet_ids = list(string)
    api_gateway_name = string
  })
}
