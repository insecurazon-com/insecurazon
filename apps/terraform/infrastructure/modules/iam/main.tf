variable "module_depends_on" {
  description = "Module dependencies"
  type = list(any)
  default = []
}

module "iam_eks" {
  module_depends_on = var.module_depends_on
  source = "./eks"
  iam_eks = var.iam_eks
}


output "iam_eks_config" {
  description = "IAM configuration for EKS"
  value = module.iam_eks.iam_eks_config
}
