module "vpc" {
  for_each = var.network_config.vpc
  source = "./vpc"
  region = var.region
  domain_name = var.domain_name
  vpc_config = each.value
  transit_gateway_id = var.transit_gateway_config.enabled ? aws_ec2_transit_gateway.this[0].id : null
}

locals {

  internet_gateway = {
    for vpc_name, vpc in module.vpc : vpc_name => vpc.vpc_config.internet_gateway
    if vpc.vpc_config.internet_gateway != null
  }[keys(module.vpc)[0]]

  peering_config = {
    for peering in var.peering_config : peering.peering_name => {
      # vpc_id = [ for vpc in module.vpc : vpc.vpc_config.vpc_id if vpc.vpc_config.vpc_name == peering.vpc_name ][0]
      vpc_id = module.vpc[peering.vpc_name].vpc_config.vpc_id
      # peer_vpc_id = [ for vpc in module.vpc : vpc.vpc_config.vpc_id if vpc.vpc_config.vpc_name == peering.peer_vpc_name ][0]
      peer_vpc_id = module.vpc[peering.peer_vpc_name].vpc_config.vpc_id
      vpc_name = peering.vpc_name
      peering_name = peering.peering_name
      tags = peering.tags
    }
  }

  routing_config = [
    for routing in var.routing_config : {
      vpc_id = module.vpc[routing.vpc_name].vpc_config.vpc_id
      vpc_name = routing.vpc_name
      subnet_ids = [ for subnet in module.vpc[routing.vpc_name].vpc_config.subnet : subnet.id if contains(routing.subnet_names, subnet.name) ]
      name = routing.name
      main_route_table = routing.main_route_table
      main_route_table_id = module.vpc[routing.vpc_name].vpc_config.main_route_table_id 
      routes = [
        for route in routing.routes : {
          destination_cidr_block = route.destination_cidr_block
          # nat_gateway_id = route.gateway == "nat_gateway" ? local.nat_gateway.id : ""
          nat_gateway_id = startswith(route.gateway, "nat_gateway:") ? [
            for nat_gateway in module.vpc[routing.vpc_name].vpc_config.nat_gateways : nat_gateway.id if "nat_gateway:${nat_gateway.name}" == route.gateway
          ][0] : ""
          transit_gateway_id = route.gateway == "transit_gateway" ? var.transit_gateway_config.enabled ? aws_ec2_transit_gateway.this[0].id : null : ""
          gateway_id = route.gateway == "internet_gateway" ? local.internet_gateway.id : ""
          vpc_peering_connection_id = startswith(route.gateway, "peer:") ? [
            for peering in module.peering : peering.peering_config.peering_id if "peer:${peering.peering_config.peering_name}" == route.gateway
          ][0] : ""
        }
      ]
      associated_endpoints = []
    }
  ]
}

module "routing" {
  count = length(local.routing_config)
  source = "./routing"
  routing_config = local.routing_config[count.index]
}

module "peering" {
  for_each = local.peering_config
  source = "./peering"
  peering_config = each.value
}

output "vpc_config" {
  value = module.vpc
}


output "routing_config" {
  value = module.routing
}
output "local_routing_config" {
  value = local.routing_config
}

output "client_vpn_enabled" {
  value = var.client_vpn_config.enabled
}

output "transit_gateway_config" {
  value = {
    transit_gateway_id = var.transit_gateway_config.enabled ? aws_ec2_transit_gateway.this[0].id : null
    route_table_id = var.transit_gateway_config.enabled ? aws_ec2_transit_gateway_route_table.this[0].id : null
    routes = [
      for route in aws_ec2_transit_gateway_route.this : {
        destination_cidr_block = route.destination_cidr_block
        transit_gateway_attachment_id = route.transit_gateway_attachment_id
      }
    ]
    attachments = {
      for attachment in aws_ec2_transit_gateway_vpc_attachment.this : attachment.tags.Name => {
        id = attachment.id
        vpc_id = attachment.vpc_id
        subnet_ids = attachment.subnet_ids
      }
    }
  }
}

output "client_vpn_config" {
  value = {
    client_vpn = local.client_vpn_enabled ? {
      endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
      client_cidr_block = aws_ec2_client_vpn_endpoint.this[0].client_cidr_block
      dns_name = aws_ec2_client_vpn_endpoint.this[0].dns_name
      vpn_port = aws_ec2_client_vpn_endpoint.this[0].vpn_port
      transport_protocol = aws_ec2_client_vpn_endpoint.this[0].transport_protocol
      security_group_id = aws_security_group.client_vpn[0].id
      certificates_generated = var.client_vpn_config.server_certificate_arn == null
      certificate_instructions = var.client_vpn_config.server_certificate_arn == null ? {
        download_client_config = "aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.this[0].id} --output text > client-vpn-config.ovpn"
        get_client_cert = "aws ssm get-parameter --name '/client-vpn/certificates/client-cert' --with-decryption --query 'Parameter.Value' --output text"
        get_client_key = "aws ssm get-parameter --name '/client-vpn/certificates/client-key' --with-decryption --query 'Parameter.Value' --output text"
      } : null
    } : null
  }
}