terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "insecurazon-terraform-state-bucket"
    key            = "path/to/your/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

module "network_config" {
  source = "./modules/network"
  region = var.region
  domain_name = var.domain_name
  network_config = local.network_config
}

module "iam_config" {
  module_depends_on = [ module.network_config ]
  source = "./modules/iam"
  iam_eks = var.iam_eks
}

# module "compute_config" {
#   module_depends_on = [ module.iam_config ]
#   source = "./modules/compute"
#   eks_config = local.eks_config
# }

module "storage_config" {
  source = "./modules/storage"
  static_website_config = local.static_website_config
  region = var.region
  module_depends_on = [ module.iam_config ]
}

output "network_config" {
  value = module.network_config
}

output "iam_config" {
  value = module.iam_config
}

# output "compute_config" {
#   value = module.compute_config
#   sensitive = true
# }


output "storage_config" {
  value = module.storage_config
}