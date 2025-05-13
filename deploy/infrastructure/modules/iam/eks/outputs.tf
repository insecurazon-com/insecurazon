output "iam_eks_config" {
  description = "IAM configuration for EKS"
  value = {
    cluster_role_arn = aws_iam_role.cluster.arn
    cluster_role_name = aws_iam_role.cluster.name
    node_role_arn = var.iam_eks.node_enabled ? aws_iam_role.node[0].arn : null
    node_role_name = var.iam_eks.node_enabled ? aws_iam_role.node[0].name : null
    fargate_role_arn = var.iam_eks.fargate_enabled ? aws_iam_role.fargate[0].arn : null
    fargate_role_name = var.iam_eks.fargate_enabled ? aws_iam_role.fargate[0].name : null
  }
}