terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "network_config" {
  source = "./modules/network"
  region = var.region
  domain_name = var.domain_name
  network_config = var.network_config
}


module "iam_config" {
  module_depends_on = [ module.network_config ]
  source = "./modules/iam"
  iam_eks = var.iam_eks
}

# module "compute_config" {
#   source = "./modules/compute"
#   eks_config = var.eks_config
# }

output "network_config" {
  value = module.network_config
}

output "iam_config" {

  value = module.iam_config
}
