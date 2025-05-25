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

# Client VPN Security Group
resource "aws_security_group" "client_vpn" {
  count = local.client_vpn_enabled ? 1 : 0
  
  name        = "client-vpn-sg"
  description = "Security group for Client VPN endpoint"
  vpc_id      = local.client_vpn_vpc_id

  # Allow all outbound traffic (needed for VPN functionality)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # Allow inbound VPN traffic on the configured port
  ingress {
    from_port   = var.client_vpn_config.vpn_port
    to_port     = var.client_vpn_config.vpn_port
    protocol    = var.client_vpn_config.transport_protocol == "udp" ? "udp" : "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow VPN connections"
  }

  tags = {
    Name = "client-vpn-security-group"
  }
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
  security_group_ids     = [aws_security_group.client_vpn[0].id]
  
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