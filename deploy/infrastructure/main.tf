terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "insecurazon-terraform-state-bucket"
    key            = "/infrastructure/terraform.tfstate"
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
  routing_config = local.routing_config
  transit_gateway_config = local.transit_gateway_config
  client_vpn_config = local.client_vpn_config
}

module "storage_config" {
  source = "./modules/storage"
  static_website_config = local.static_website_config
  region = var.region
  module_depends_on = [ module.network_config ]
}

# module "database_config" {
#   module_depends_on = [ module.network_config ]
#   source = "./modules/database"
#   documentdb_elastic_config = local.documentdb_elastic_config
# }

module "compute_config" {
  module_depends_on = [ module.storage_config ]
  source = "./modules/compute"
  eks_config = local.eks_config
  lambda_config = local.lambda_config
  argocd_config = local.argocd_config
  network_config = module.network_config
}

output "network_config" {
  value = module.network_config
}

output "compute_config" {
  value = module.compute_config
  sensitive = true
}

output "storage_config" {
  value = module.storage_config
}

# output "database_config" {
#   value = module.database_config
#   sensitive = true
# }