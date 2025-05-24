resource "aws_security_group" "cluster" {
  name        = "${var.eks_config.cluster_name}-cluster"
  description = "EKS cluster security group"
  vpc_id      = var.eks_config.vpc_id

  tags = merge(
    var.eks_config.tags,
    {
      "Name" = "${var.eks_config.cluster_name}-cluster"
    }
  )
}

resource "aws_security_group_rule" "cluster_egress" {
  description       = "Allow cluster egress access"
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

# Allow Lambda to connect to EKS cluster API
resource "aws_security_group_rule" "cluster_ingress_lambda" {
  count                    = var.install_argocd ? 1 : 0
  description              = "Allow Lambda to connect to EKS cluster API"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.lambda[0].id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

# Allow Client VPN to connect to EKS cluster API
resource "aws_security_group_rule" "cluster_ingress_client_vpn" {
  count                    = try(var.network_config.client_vpn_enabled, false) ? 1 : 0
  description              = "Allow Client VPN to connect to EKS cluster API"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = var.network_config.transit_gateway_config.client_vpn.security_group_id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

# Create security group for Lambda
resource "aws_security_group" "lambda" {
  count       = var.install_argocd ? 1 : 0
  name        = "${var.eks_config.cluster_name}-lambda-sg"
  description = "Security group for Lambda function that installs ArgoCD"
  vpc_id      = var.eks_config.vpc_id

  # Allow outbound HTTPS traffic to the private EKS endpoint
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.cluster.id]
    description = "Allow HTTPS traffic to EKS cluster endpoint"
  }

  tags = merge(
    var.eks_config.tags,
    {
      Name = "${var.eks_config.cluster_name}-lambda-sg"
    }
  )
}