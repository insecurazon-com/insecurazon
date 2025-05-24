resource "aws_ec2_transit_gateway" "this" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description = "Transit Gateway"
  tags = {
    Name = "transit-gateway"
  }
}
variable "transit_gateway_config" {
type = object({
  attachments = map(object({
    vpc_name = string
    subnets = list(string)
    appliance_mode_support = string
  }))
  routes = list(object({
    destination_cidr_block = string
    transit_gateway_attachment = string
  }))
})
}

locals {
  transit_gateway_attachments = [
    for config in var.transit_gateway_config.attachments : {
      vpc_id = [ for vpc in module.vpc : vpc.vpc_config.vpc_id if vpc.vpc_config.vpc_name == config.vpc_name ][0]
      vpc_name = config.vpc_name
      subnet_ids = [ for subnet in module.vpc[config.vpc_name].vpc_config.subnet : subnet.id if contains(config.subnets, subnet.name) ]
      appliance_mode_support = config.appliance_mode_support
    }
  ]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = length(local.transit_gateway_attachments)
  subnet_ids = local.transit_gateway_attachments[count.index].subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id = local.transit_gateway_attachments[count.index].vpc_id
  appliance_mode_support = local.transit_gateway_attachments[count.index].appliance_mode_support
  tags = {
    Name = "transit-gateway-attachment-${local.transit_gateway_attachments[count.index].vpc_name}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = "transit-gateway-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = {
    for attachment in aws_ec2_transit_gateway_vpc_attachment.this : attachment.tags.Name => attachment.id
  }
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id = each.value
}

# Add the missing route table associations
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = {
    for attachment in aws_ec2_transit_gateway_vpc_attachment.this : attachment.tags.Name => attachment.id
  }
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id = each.value
}

resource "aws_ec2_transit_gateway_route" "this" {
  count = length(var.transit_gateway_config.routes) 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  destination_cidr_block = var.transit_gateway_config.routes[count.index].destination_cidr_block
  transit_gateway_attachment_id = [
    for attachment in aws_ec2_transit_gateway_vpc_attachment.this : attachment.id
    if attachment.tags.Name == "transit-gateway-attachment-${var.transit_gateway_config.routes[count.index].transit_gateway_attachment}"
  ][0]
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
    client_vpn = local.client_vpn_enabled ? {
      endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
      client_cidr_block = aws_ec2_client_vpn_endpoint.this[0].client_cidr_block
      dns_name = aws_ec2_client_vpn_endpoint.this[0].dns_name
      vpn_port = aws_ec2_client_vpn_endpoint.this[0].vpn_port
      transport_protocol = aws_ec2_client_vpn_endpoint.this[0].transport_protocol
      security_group_id = tolist(aws_ec2_client_vpn_endpoint.this[0].security_group_ids)[0]
      certificates_generated = var.client_vpn_config.server_certificate_arn == null
      certificate_instructions = var.client_vpn_config.server_certificate_arn == null ? {
        download_client_config = "aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.this[0].id} --output text > client-vpn-config.ovpn"
        get_client_cert = "aws ssm get-parameter --name '/client-vpn/certificates/client-cert' --with-decryption --query 'Parameter.Value' --output text"
        get_client_key = "aws ssm get-parameter --name '/client-vpn/certificates/client-key' --with-decryption --query 'Parameter.Value' --output text"
      } : null
    } : null
  }
}

# Client VPN Configuration
locals {
  client_vpn_enabled = var.client_vpn_config.enabled
  
  # Find the VPC and subnets for Client VPN attachment
  client_vpn_vpc_id = local.client_vpn_enabled ? [
    for vpc in module.vpc : vpc.vpc_config.vpc_id 
    if vpc.vpc_config.vpc_name == var.client_vpn_config.vpc_name
  ][0] : null
  
  client_vpn_subnet_ids = local.client_vpn_enabled ? [
    for subnet in module.vpc[var.client_vpn_config.vpc_name].vpc_config.subnet : subnet.id 
    if contains(var.client_vpn_config.subnet_names, subnet.name)
  ] : []
}

# Client VPN Endpoint
resource "aws_ec2_client_vpn_endpoint" "this" {
  count = local.client_vpn_enabled ? 1 : 0
  
  description            = "Client VPN for Transit Gateway access"
  server_certificate_arn = local.server_certificate_arn
  client_cidr_block      = var.client_vpn_config.client_cidr_block
  split_tunnel           = var.client_vpn_config.split_tunnel
  vpn_port              = var.client_vpn_config.vpn_port
  transport_protocol    = var.client_vpn_config.transport_protocol
  
  # DNS configuration
  dns_servers = var.client_vpn_config.dns_servers
  
  # Authentication configuration
  authentication_options {
    type = var.client_vpn_config.authentication_type
    
    # Certificate authentication
    root_certificate_chain_arn = var.client_vpn_config.authentication_type == "certificate-authentication" ? local.client_certificate_arn : null
    
    # Directory service authentication
    active_directory_id = var.client_vpn_config.authentication_type == "directory-service-authentication" ? var.client_vpn_config.directory_id : null
  }
  
  # Connection logging
  connection_log_options {
    enabled = false
  }
  
  tags = {
    Name = "client-vpn-endpoint"
  }
}

# Client VPN Network Associations
resource "aws_ec2_client_vpn_network_association" "this" {
  count = local.client_vpn_enabled ? length(local.client_vpn_subnet_ids) : 0
  
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  subnet_id              = local.client_vpn_subnet_ids[count.index]
  
  lifecycle {
    ignore_changes = [subnet_id]
  }
}

# Client VPN Authorization Rules
resource "aws_ec2_client_vpn_authorization_rule" "this" {
  count = local.client_vpn_enabled ? length(var.client_vpn_config.authorization_rules) : 0
  
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  target_network_cidr    = var.client_vpn_config.authorization_rules[count.index].target_network_cidr
  authorize_all_groups   = true
  description           = var.client_vpn_config.authorization_rules[count.index].description
  
  # Add explicit dependency to ensure endpoint is ready
  depends_on = [aws_ec2_client_vpn_network_association.this]
}

# Client VPN Routes to access resources through Transit Gateway
resource "aws_ec2_client_vpn_route" "to_transit_gateway" {
  count = local.client_vpn_enabled && var.client_vpn_config.connect_to_transit_gateway ? length(local.client_vpn_subnet_ids) : 0
  
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  destination_cidr_block = "0.0.0.0/0"  # Default route to allow internet access via VPC
  target_vpc_subnet_id   = local.client_vpn_subnet_ids[count.index]
  description           = "Route to internet via VPC"
  
  depends_on = [aws_ec2_client_vpn_network_association.this]
}
