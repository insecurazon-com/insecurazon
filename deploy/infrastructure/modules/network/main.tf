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
      vpc_name = routing.vpc_name
      subnet_id = [ for subnet in module.vpc[routing.vpc_name].vpc_config.subnet : subnet.id if subnet.name == "${routing.vpc_name}-${routing.subnet_name}" ][0]
      subnet_name = routing.subnet_name
      routes = [
        for route in routing.routes : {
          destination_cidr_block = route.destination_cidr_block
          nat_gateway_id = route.gateway == "nat_gateway" ? (
            # Find the appropriate NAT Gateway for this subnet based on availability zone
            routing.vpc_name == "egress" && contains(["nat-1", "nat-2", "nat-3"], routing.subnet_name) ? 
              module.vpc[routing.vpc_name].vpc_config.nat_gateways[routing.subnet_name].id :
              local.nat_gateway.id
          ) : ""
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

output "transit_gateway_config" {
  value = {
    transit_gateway_id = aws_ec2_transit_gateway.this.id
    route_table_id = aws_ec2_transit_gateway_route_table.this.id
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