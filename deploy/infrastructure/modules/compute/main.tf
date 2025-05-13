variable "module_depends_on" {
  description = "A list of modules that must be created before this one"
  type = list(any)
}

module "eks" {
  source = "./eks"
  eks_config = var.eks_config
  module_depends_on = var.module_depends_on
}


output "eks_config" {
  value = module.eks.eks_config
}