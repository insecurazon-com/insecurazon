
# Lambda function for ArgoCD installation
data "archive_file" "lambda_zip" {
  count       = var.install_argocd ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}


resource "aws_iam_role" "lambda" {
  count = var.install_argocd ? 1 : 0
  name  = "${var.eks_config.cluster_name}-argocd-installer"

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

resource "aws_lambda_function" "argocd_installer" {
  count         = var.install_argocd ? 1 : 0
  filename      = data.archive_file.lambda_zip[0].output_path
  function_name = "${var.eks_config.cluster_name}-argocd-installer"
  role          = aws_iam_role.lambda[0].arn
  handler       = "install_argocd.lambda_handler"
  runtime       = "python3.9"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  vpc_config {
    subnet_ids         = var.eks_config.subnet_ids
    security_group_ids = [aws_security_group.lambda[0].id]
  }

  environment {
    variables = {
      CLUSTER_NAME = var.eks_config.cluster_name
      AWS_REGION   = data.aws_region.current.name
    }
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy.lambda
  ]
}

resource "aws_lambda_invocation" "argocd_installer" {
  count         = var.install_argocd ? 1 : 0
  function_name = aws_lambda_function.argocd_installer[0].function_name

  input = jsonencode({
    cluster_name = var.eks_config.cluster_name
    region       = data.aws_region.current.name
    argocd_config = var.argocd_config
  })

  depends_on = [
    aws_lambda_function.argocd_installer,
    aws_eks_cluster.this
  ]
}
