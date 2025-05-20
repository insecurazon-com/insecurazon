# Cluster IAM role
resource "aws_iam_role" "cluster" {
  depends_on = [var.module_depends_on]
  name = "${var.eks_config.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.eks_config.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# Node groups IAM role
resource "aws_iam_role" "node" {
  depends_on = [var.module_depends_on]
  count = var.eks_config.node_groups != null && length(var.eks_config.node_groups) > 0 ? 1 : 0
  name = "${var.eks_config.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.eks_config.tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  count = var.eks_config.node_groups != null && length(var.eks_config.node_groups) > 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node[count.index].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  count = var.eks_config.node_groups != null && length(var.eks_config.node_groups) > 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node[count.index].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  count = var.eks_config.node_groups != null && length(var.eks_config.node_groups) > 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node[count.index].name
}

# Fargate IAM role
resource "aws_iam_role" "fargate" {
  depends_on = [var.module_depends_on]
  count = var.eks_config.fargate_profiles != null && length(var.eks_config.fargate_profiles) > 0 ? 1 : 0
  name = "${var.eks_config.cluster_name}-fargate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  tags = var.eks_config.tags
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role_policy" {
  count = var.eks_config.fargate_profiles != null && length(var.eks_config.fargate_profiles) > 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate[count.index].name
} 