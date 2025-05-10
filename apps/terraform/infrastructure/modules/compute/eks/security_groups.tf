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