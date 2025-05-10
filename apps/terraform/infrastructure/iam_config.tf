variable "iam_eks" {
  description = "IAM configuration for EKS"
  type = object({
    cluster_name = string
    fargate_enabled = bool
    node_enabled = bool
    tags = map(string)
  })
  default = {
    cluster_name = "eks-cluster"
    fargate_enabled = true
    node_enabled = false
    tags = {}
  }
}