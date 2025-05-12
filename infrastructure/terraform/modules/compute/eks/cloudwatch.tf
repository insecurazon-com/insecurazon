resource "aws_cloudwatch_log_group" "this" {
  depends_on = [ var.module_depends_on ]
  count = var.eks_config.cloudwatch.enabled ? 1 : 0
  name              = "/aws/eks/${var.eks_config.cluster_name}/cluster"
  retention_in_days = var.eks_config.cloudwatch.retention_in_days
  tags              = var.eks_config.tags
}
