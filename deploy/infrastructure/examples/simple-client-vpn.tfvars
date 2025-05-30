# Simple Client VPN Configuration Example
# This example shows how to enable Client VPN with automatic certificate generation

# Enable Client VPN with automatic certificate generation
client_vpn_config = {
  enabled = true
  
  # Network configuration
  client_cidr_block = "192.168.100.0/22"  # VPN client IP range (non-overlapping with VPC CIDRs)
  vpc_name = "main-vpc"                    # Replace with your VPC name
  subnet_names = ["private-subnet-1"]      # Replace with your subnet names
  
  # Automatic certificate generation (leave these commented for auto-generation)
  authentication_type = "certificate-authentication"
  # server_certificate_arn = null  # Auto-generated
  # client_certificate_arn = null  # Auto-generated
  
  # VPN settings
  dns_servers = ["10.0.0.2"]  # Use your VPC's DNS
  split_tunnel = true          # Only route specified networks through VPN
  vpn_port = 443
  transport_protocol = "udp"
  
  # Define which networks VPN clients can access
  # Make sure these don't overlap with client_cidr_block!
  authorization_rules = [
    {
      target_network_cidr = "10.0.0.0/16"   # Specific VPC CIDR (adjust to your VPCs)
      description = "Access to main VPC"
    },
    {
      target_network_cidr = "10.1.0.0/16"   # Additional VPC CIDR (adjust to your VPCs)
      description = "Access to secondary VPC"
    }
  ]
  
  # Enable integration with Transit Gateway for multi-VPC access
  connect_to_transit_gateway = true
}

# Your other configuration variables...
# region = "us-east-1"
# domain_name = "example.local"
# network_config = { ... }
# routing_config = [ ... ]
# transit_gateway_config = { ... } 