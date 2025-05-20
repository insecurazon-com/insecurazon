locals {
  lambda_function_name = "documentdb-user-creator-${var.environment}"
  lambda_zip_path      = "${path.module}/lambda_dist/create_users_lambda.zip"
  lambda_source_dir    = "${path.module}/lambda"
}

# Create a ZIP file of the Lambda function code and its dependencies
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = local.lambda_zip_path
  source_dir  = local.lambda_source_dir
}

# The Lambda function
resource "aws_lambda_function" "docdb_user_creator" {
  function_name    = local.lambda_function_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "create_users.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 300
  memory_size      = 256

  environment {
    variables = {
      DOCDB_ENDPOINT    = aws_docdbelastic_cluster.documentdb_elastic.endpoint
      ADMIN_SECRET_NAME = aws_secretsmanager_secret.documentdb_password.name
      ENVIRONMENT       = var.environment
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [
    aws_docdbelastic_cluster.documentdb_elastic,
    aws_secretsmanager_secret.documentdb_password,
    aws_secretsmanager_secret_version.documentdb_password,
    aws_secretsmanager_secret.app_user_password,
    aws_secretsmanager_secret_version.app_user_password
  ]

  tags = var.tags
}

# Trigger Lambda execution after resource creation
resource "null_resource" "invoke_lambda" {
  triggers = {
    docdb_cluster_id = aws_docdbelastic_cluster.documentdb_elastic.id
  }

  provisioner "local-exec" {
    command = <<EOT
      aws lambda invoke \
        --function-name ${aws_lambda_function.docdb_user_creator.function_name} \
        --region ${data.aws_region.current.name} \
        /tmp/lambda_output.json || echo "Lambda invocation failed but continuing"
    EOT
  }

  depends_on = [
    aws_lambda_function.docdb_user_creator
  ]
}