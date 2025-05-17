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

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${local.lambda_function_name}-role"

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

  tags = var.tags
}

# IAM policy for the Lambda function to access Secrets Manager
resource "aws_iam_policy" "lambda_secrets_policy" {
  name        = "${local.lambda_function_name}-secrets-policy"
  description = "Allow Lambda function to access Secrets Manager for DocumentDB credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# IAM policy for Lambda to access VPC (to reach DocumentDB)
resource "aws_iam_policy" "lambda_vpc_policy" {
  name        = "${local.lambda_function_name}-vpc-policy"
  description = "Allow Lambda function to access VPC for DocumentDB connection"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Logs policy for Lambda
resource "aws_iam_policy" "lambda_logs_policy" {
  name        = "${local.lambda_function_name}-logs-policy"
  description = "Allow Lambda function to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policies to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_secrets_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_vpc_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

# Lambda security group
resource "aws_security_group" "lambda_sg" {
  name        = "${local.lambda_function_name}-sg"
  description = "Security group for DocumentDB user creator Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.lambda_function_name}-sg"
  })
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

# CloudWatch Logs group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 14
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

# Current AWS Region
data "aws_region" "current" {} 