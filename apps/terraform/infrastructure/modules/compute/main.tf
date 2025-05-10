module "eks" {
  source = "./eks"
  eks_config = var.eks_config
}


output "eks_config" {
  value = module.eks.eks_config
}