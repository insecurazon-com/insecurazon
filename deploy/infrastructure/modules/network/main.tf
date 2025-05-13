module "vpc" {
  for_each = var.network_config.vpc
  source = "./vpc"
  region = var.region
  domain_name = var.domain_name
  vpc_config = each.value
}

module "peering" {
  module_depends_on = [ module.vpc ]
  for_each = var.network_config.peering
  source = "./peering"
  vpc_id = module.vpc[each.value.vpc_name].vpc_config.vpc_id
  peer_vpc_id = module.vpc[each.value.peer_vpc_name].vpc_config.vpc_id
  tags = each.value.tags
}

output "vpc_config" {
  value = module.vpc
}

output "peering_config" {
  value = module.peering
}