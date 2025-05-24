# Client VPN Setup for Transit Gateway

This guide explains how to configure AWS Client VPN to connect your laptop to the Transit Gateway, allowing access to all connected VPCs.

## Prerequisites

1. **AWS CLI**: For downloading client configuration and managing certificates
2. **Terraform**: For infrastructure deployment
3. **OpenSSL**: For certificate generation (if using manual method)

## Certificate Generation

You have **three options** for generating certificates:

### Option A: Automatic Generation with Terraform (Recommended)

The Terraform configuration automatically generates certificates when you don't provide `server_certificate_arn` and `client_certificate_arn`:

```hcl
client_vpn_config = {
  enabled = true
  client_cidr_block = "10.200.0.0/16"
  vpc_name = "your-vpc-name"
  subnet_names = ["private-subnet-1", "private-subnet-2"]
  
  # Leave these empty for automatic generation
  authentication_type = "certificate-authentication"
  # server_certificate_arn = null  # Will be auto-generated
  # client_certificate_arn = null  # Will be auto-generated
  
  authorization_rules = [
    {
      target_network_cidr = "10.0.0.0/8"
      description = "Access to private networks"
    }
  ]
  
  connect_to_transit_gateway = true
}
```

The certificates will be:
- Generated using the Terraform TLS provider
- Automatically uploaded to AWS Certificate Manager
- Stored in AWS Systems Manager Parameter Store for easy retrieval

### Option B: Shell Script Generation

Use the provided script to generate certificates manually:

```bash
# Run the certificate generation script
./deploy/infrastructure/scripts/generate-client-vpn-certificates.sh

# With custom organization
VPN_ORG="MyCompany" ./deploy/infrastructure/scripts/generate-client-vpn-certificates.sh

# With custom region
./deploy/infrastructure/scripts/generate-client-vpn-certificates.sh --region eu-west-1
```

This will:
- Generate CA, server, and client certificates
- Upload them to AWS Certificate Manager
- Store them in SSM Parameter Store
- Create a Terraform configuration snippet
- Provide a helper script for client setup

### Option C: Manual Generation with OpenSSL

If you prefer manual control, follow these steps:

```bash
# 1. Create CA certificate and key
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -out ca.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=VPN-CA"

# 2. Create server certificate and key
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=VPN-Server"
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# 3. Create client certificate and key
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=VPN-Client"
openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt

# 4. Upload to AWS Certificate Manager
aws acm import-certificate \
  --certificate file://server.crt \
  --certificate-chain file://ca.crt \
  --private-key file://server.key \
  --region us-east-1

aws acm import-certificate \
  --certificate file://ca.crt \
  --private-key file://ca.key \
  --region us-east-1
```

## Terraform Configuration

Add the following to your Terraform configuration where you call the network module:

```hcl
module "network" {
  source = "./modules/network"
  
  # ... your existing configuration ...
  
  # Client VPN Configuration
  client_vpn_config = {
    enabled = true
    
    # Network settings
    client_cidr_block = "10.200.0.0/16"  # CIDR for VPN clients (must not overlap with VPCs)
    vpc_name = "your-vpc-name"  # VPC to attach Client VPN to
    subnet_names = ["private-subnet-1", "private-subnet-2"]  # Subnets for association
    
    # Authentication - leave empty for auto-generation or provide ARNs
    authentication_type = "certificate-authentication"
    # server_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/server-cert-id"  # Optional
    # client_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/client-ca-cert-id"  # Optional
    
    # VPN settings
    dns_servers = ["10.0.0.2"]  # Optional: DNS servers for clients
    split_tunnel = true  # Recommended: only route specific traffic through VPN
    vpn_port = 443
    transport_protocol = "udp"
    
    # Authorization rules - define accessible networks
    authorization_rules = [
      {
        target_network_cidr = "10.0.0.0/8"
        description = "Access to private networks"
      },
      {
        target_network_cidr = "172.16.0.0/12"
        description = "Access to secondary private networks"
      }
    ]
    
    # Enable Transit Gateway integration
    connect_to_transit_gateway = true
  }
  
  # ... rest of your configuration ...
}
```

## Deploy the Infrastructure

```bash
terraform plan
terraform apply
```

**Note**: EKS integration is fully automatic! The EKS module in `modules/compute/eks` automatically detects when Client VPN is enabled and creates the necessary security group rules for seamless connectivity. No manual configuration needed.

## Prepare Client Configuration

After deployment, you have multiple ways to prepare your client configuration:

### Method 1: Automated (for Terraform-generated certificates)

If certificates were auto-generated, Terraform output will show the commands:

```bash
# Check Terraform output for instructions
terraform output

# The output will show commands like:
# aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id cvpn-endpoint-xxx --output text > client-vpn-config.ovpn
# aws ssm get-parameter --name '/client-vpn/certificates/client-cert' --with-decryption --query 'Parameter.Value' --output text
# aws ssm get-parameter --name '/client-vpn/certificates/client-key' --with-decryption --query 'Parameter.Value' --output text
```

### Method 2: Using the Helper Script (if generated via shell script)

```bash
# Use the helper script created by the certificate generation script
cd deploy/infrastructure/scripts/client-vpn-certificates/
./prepare-client-config.sh cvpn-endpoint-xxxxxxxxx
```

### Method 3: Manual Preparation

```bash
# Get the Client VPN Endpoint ID from Terraform output
terraform output

# Download client configuration
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxxxxxx \
  --output text > client-vpn-config.ovpn

# Get certificates (adjust paths/methods based on your certificate source)
# For SSM-stored certificates:
aws ssm get-parameter --name '/client-vpn/certificates/client-cert' --with-decryption --query 'Parameter.Value' --output text > client.crt
aws ssm get-parameter --name '/client-vpn/certificates/client-key' --with-decryption --query 'Parameter.Value' --output text > client.key

# For local certificates:
# Use your local client.crt and client.key files

# Append certificates to configuration
echo "" >> client-vpn-config.ovpn
echo "<cert>" >> client-vpn-config.ovpn
cat client.crt >> client-vpn-config.ovpn
echo "</cert>" >> client-vpn-config.ovpn
echo "" >> client-vpn-config.ovpn
echo "<key>" >> client-vpn-config.ovpn
cat client.key >> client-vpn-config.ovpn
echo "</key>" >> client-vpn-config.ovpn

# Clean up temporary files
rm client.crt client.key
```

## Connect with Your Laptop

### macOS/Linux
Use OpenVPN client:
```bash
# Install OpenVPN (macOS with Homebrew)
brew install openvpn

# Connect
sudo openvpn --config client-vpn-config.ovpn
```

### Windows
1. Download and install OpenVPN Connect or OpenVPN GUI
2. Import the `client-vpn-config.ovpn` file
3. Connect

### Alternative: GUI Clients
- **Tunnelblick** (macOS)
- **OpenVPN Connect** (cross-platform)
- **Viscosity** (commercial, cross-platform)

## Configuration Options

### Authentication Types

1. **Certificate Authentication** (default):
   ```hcl
   authentication_type = "certificate-authentication"
   # server_certificate_arn and client_certificate_arn are optional - will auto-generate if not provided
   ```

2. **Active Directory Authentication** (enterprise):
   ```hcl
   authentication_type = "directory-service-authentication"
   directory_id = "d-xxxxxxxxxx"
   ```

### Network Configuration

- **client_cidr_block**: CIDR range for VPN clients (must not overlap with VPC CIDRs)
- **split_tunnel**: `true` routes only specified networks through VPN, `false` routes all traffic
- **authorization_rules**: Define which networks clients can access

⚠️ **Important**: The `client_cidr_block` must not overlap with any of the `target_network_cidr` values in authorization rules. 

**Good example:**
```hcl
client_cidr_block = "192.168.100.0/22"  # VPN clients
authorization_rules = [
  {
    target_network_cidr = "10.0.0.0/16"   # VPC networks
    description = "Access to main VPC"
  }
]
```

**Bad example (will cause errors):**
```hcl
client_cidr_block = "10.200.0.0/16"     # VPN clients  
authorization_rules = [
  {
    target_network_cidr = "10.0.0.0/8"    # ❌ Overlaps with client CIDR!
    description = "Access to private networks"
  }
]
```

### DNS Configuration

```hcl
dns_servers = ["10.0.0.2", "8.8.8.8"]  # Use VPC DNS + public DNS
```

## Certificate Management

### Automatic Certificate Rotation

For production environments, consider implementing certificate rotation:

1. **Monitor certificate expiration** using CloudWatch or external tools
2. **Automate renewal** using Lambda functions or scheduled scripts
3. **Update ACM certificates** and restart Client VPN endpoint if needed

### Certificate Storage

Certificates are stored in multiple locations for redundancy:
- **AWS Certificate Manager**: For AWS service integration
- **AWS Systems Manager Parameter Store**: For programmatic access
- **Local files** (if using shell script): For backup and manual operations

## Troubleshooting

### Common Issues

1. **Certificate errors**: Ensure certificates are valid and uploaded to ACM in the correct region
2. **Network connectivity**: Check security groups and NACLs allow VPN traffic
3. **Authorization failures**: Verify authorization rules include the target networks
4. **DNS resolution**: Configure appropriate DNS servers for your environment

### Verification Commands

```bash
# Check Client VPN status
aws ec2 describe-client-vpn-endpoints

# Check network associations
aws ec2 describe-client-vpn-target-networks --client-vpn-endpoint-id cvpn-endpoint-xxxxxxxxx

# Check authorization rules
aws ec2 describe-client-vpn-authorization-rules --client-vpn-endpoint-id cvpn-endpoint-xxxxxxxxx

# Check routes
aws ec2 describe-client-vpn-routes --client-vpn-endpoint-id cvpn-endpoint-xxxxxxxxx

# Check certificates in ACM
aws acm list-certificates --region us-east-1

# Check certificates in SSM
aws ssm get-parameters-by-path --path "/client-vpn/certificates" --recursive
```

## Security Considerations

1. **Certificate Management**: Regularly rotate certificates and revoke compromised ones
2. **Network Segmentation**: Use authorization rules to limit access to only required networks
3. **Monitoring**: Enable connection logging and monitor VPN usage
4. **Split Tunneling**: Consider whether to route all traffic or only specific networks through VPN
5. **Access Control**: Use IAM policies to control who can manage Client VPN resources

## Cost Considerations

- Client VPN charges per endpoint-hour and per connection-hour
- Each subnet association incurs additional charges
- Consider connection patterns and optimize accordingly
- Certificate Manager is free for AWS services

## Next Steps

After successful connection, you should be able to:
1. Access resources in all VPCs connected to the Transit Gateway
2. Resolve private DNS names (if DNS is configured)
3. Use private IP addresses for all resources

To verify connectivity, try pinging or connecting to resources in your VPCs using their private IP addresses. 