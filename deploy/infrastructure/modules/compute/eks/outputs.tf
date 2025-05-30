output "eks_config" {
  description = "EKS configuration"
  value = {
    cluster_id = aws_eks_cluster.this.id
    cluster_arn = aws_eks_cluster.this.arn
    cluster_endpoint = aws_eks_cluster.this.endpoint
    cluster_certificate_authority_data = aws_eks_cluster.this.certificate_authority[0].data
    cluster_security_group_id = aws_security_group.cluster.id
    cluster_role_arn = aws_iam_role.cluster.arn
    node_role_arn = var.eks_config.node_groups != null && length(var.eks_config.node_groups) > 0 ? aws_iam_role.node[0].arn : null
    fargate_pod_execution_role_arn = var.eks_config.fargate_profiles != null && length(var.eks_config.fargate_profiles) > 0 ? aws_iam_role.fargate[0].arn : null
    node_groups = aws_eks_node_group.this
    fargate_profiles = aws_eks_fargate_profile.this
    kubeconfig = templatefile("${path.module}/templates/kubeconfig.tpl", {
      cluster_name                  = aws_eks_cluster.this.name
      cluster_endpoint              = aws_eks_cluster.this.endpoint
      cluster_certificate_authority = aws_eks_cluster.this.certificate_authority[0].data
    })
  }
  sensitive = true
}