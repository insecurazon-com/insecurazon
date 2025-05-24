module "vpc" {
  for_each = var.network_config.vpc
  source = "./vpc"
  region = var.region
  domain_name = var.domain_name
  vpc_config = each.value
  transit_gateway_id = aws_ec2_transit_gateway.this.id
}

locals {
  nat_gateway = {
    for vpc_name, vpc in module.vpc : vpc_name => vpc.vpc_config.nat_gateway
    if vpc.vpc_config.nat_gateway != null
  }[keys(module.vpc)[0]]

  internet_gateway = {
    for vpc_name, vpc in module.vpc : vpc_name => vpc.vpc_config.internet_gateway
    if vpc.vpc_config.internet_gateway != null
  }[keys(module.vpc)[0]]

  routing_config = {
    for routing in var.routing_config : "${routing.vpc_name}-${routing.subnet_name}" => {
      vpc_id = module.vpc[routing.vpc_name].vpc_config.vpc_id
      # vpc_id = [ for vpc in module.vpc : vpc.vpc_config.vpc_id if vpc.vpc_config.vpc_name == routing.vpc_name ][0]
      vpc_name = routing.vpc_name
      subnet_id = [ for subnet in module.vpc[routing.vpc_name].vpc_config.subnet : subnet.id if subnet.name == "${routing.vpc_name}-${routing.subnet_name}" ][0]
      subnet_name = routing.subnet_name
      routes = [
        for route in routing.routes : {
          destination_cidr_block = route.destination_cidr_block
          nat_gateway_id = route.gateway == "nat_gateway" ? local.nat_gateway.id   : ""
          transit_gateway_id = route.gateway == "transit_gateway" ? aws_ec2_transit_gateway.this.id : ""
          gateway_id = route.gateway == "internet_gateway" ? local.internet_gateway.id : ""
        }
      ]
      associated_endpoints = []
    }
  }
}

module "routing" {
  for_each = local.routing_config
  source = "./routing"
  routing_config = each.value
}

output "vpc_config" {
  value = module.vpc
}

output "routing_config" {
  value = module.routing
}

output "client_vpn_enabled" {
  value = var.client_vpn_config.enabled
}