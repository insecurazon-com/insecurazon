variable "module_depends_on" {
  description = "A list of resources to depend on"
  type        = list(any)
  default     = []
}

resource "aws_eks_cluster" "this" {
  depends_on = [
    var.module_depends_on,
    aws_cloudwatch_log_group.this
  ]
  name     = var.eks_config.cluster_name
  role_arn = var.eks_config.cluster_role_arn
  version  = var.eks_config.cluster_version != null ? var.eks_config.cluster_version : var.default_cluster_version

  vpc_config {
    subnet_ids              = var.eks_config.subnet_ids
    endpoint_private_access = var.eks_config.access.private != null ? var.eks_config.access.private : true
    endpoint_public_access  = var.eks_config.access.public != null ? var.eks_config.access.public : false
    public_access_cidrs     = var.eks_config.access.cidrs != null ? var.eks_config.access.cidrs : ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = var.eks_config.cloudwatch.enabled ? (var.eks_config.log_types != null ? var.eks_config.log_types : var.default_cluster_enabled_log_types) : []

  dynamic "encryption_config" {
    for_each = length(var.eks_config.cluster_encryption_config) > 0 ? var.eks_config.cluster_encryption_config : []
    content {
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  tags = merge(
    var.eks_config.tags,
    {
      "Name" = var.eks_config.cluster_name
    }
  )
}

# Node groups
resource "aws_eks_node_group" "this" {
  depends_on = [
    var.module_depends_on,
    aws_eks_cluster.this
  ]
  for_each = var.eks_config.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.value.name
  node_role_arn   = var.eks_config.node_role_arn
  subnet_ids      = each.value.subnet_ids != null ? each.value.subnet_ids : var.eks_config.subnet_ids

  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  dynamic "taint" {
    for_each = each.value.taints != null ? each.value.taints : []
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  labels = each.value.labels

  tags = merge(
    var.eks_config.tags,
    {
      "Name" = each.value.name
    }
  )
}

# Fargate profiles
resource "aws_eks_fargate_profile" "this" {
  depends_on = [
    var.module_depends_on,
    aws_eks_cluster.this
  ]
  for_each = var.eks_config.fargate_profiles

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = each.value.name
  pod_execution_role_arn = var.eks_config.fargate_pod_execution_role_arn
  subnet_ids             = each.value.subnet_ids != null ? each.value.subnet_ids : var.eks_config.subnet_ids

  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = merge(
    var.eks_config.tags,
    {
      "Name" = each.value.name
    }
  )
}
