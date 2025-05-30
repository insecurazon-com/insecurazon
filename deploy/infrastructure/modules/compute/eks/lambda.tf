# Lambda function for ArgoCD installation
data "archive_file" "lambda_zip" {
  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    aws_eks_fargate_profile.this
  ]
  count       = var.install_argocd ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "null_resource" "prepare_lambda_layer" {
  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    aws_eks_fargate_profile.this
  ]
  count = var.install_argocd ? 1 : 0

  triggers = {
    requirements_hash = filemd5("${path.module}/lambda/requirements.txt")
    source_code_hash = filemd5("${path.module}/lambda/install_argocd.py")
    force_deploy = timestamp() # This will force redeployment every time
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/layer/python && \
      python3 -m pip install -r ${path.module}/lambda/requirements.txt --target ${path.module}/layer/python
    EOT
  }
}

data "archive_file" "lambda_layer" {
  count       = var.install_argocd ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/layer"
  output_path = "${path.module}/lambda_layer.zip"
  depends_on  = [null_resource.prepare_lambda_layer]
}

resource "aws_lambda_layer_version" "dependencies" {
  count               = var.install_argocd ? 1 : 0
  layer_name          = "${var.eks_config.cluster_name}-argocd-installer-dependencies"
  description         = "Dependencies for ArgoCD installer Lambda"
  filename            = data.archive_file.lambda_layer[0].output_path
  compatible_runtimes = ["python3.9"]
}

# Get EKS cluster authentication token
data "aws_eks_cluster_auth" "cluster" {
  count = var.install_argocd ? 1 : 0
  name  = aws_eks_cluster.this.name
}

# Using existing IAM role and security group (defined in iam.tf and security_groups.tf)

resource "aws_lambda_function" "argocd_installer" {
  count         = var.install_argocd ? 1 : 0
  filename      = data.archive_file.lambda_zip[0].output_path
  function_name = "${var.eks_config.cluster_name}-argocd-installer"
  role          = aws_iam_role.lambda[0].arn
  handler       = "install_argocd.lambda_handler"
  runtime       = "python3.9"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  
  layers = [
    aws_lambda_layer_version.dependencies[0].arn
  ]

  vpc_config {
    subnet_ids         = var.eks_config.subnet_ids
    security_group_ids = [aws_security_group.lambda[0].id]
  }
  
  environment {
    variables = {
      CLUSTER_NAME     = var.eks_config.cluster_name
      REGION           = data.aws_region.current.name
      DEBUG            = "true"
      CLUSTER_ENDPOINT = aws_eks_cluster.this.endpoint
      CLUSTER_CA       = aws_eks_cluster.this.certificate_authority[0].data
      CLUSTER_TOKEN    = data.aws_eks_cluster_auth.cluster[0].token
    }
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    aws_eks_fargate_profile.this
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
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    aws_eks_fargate_profile.this
  ]
}
