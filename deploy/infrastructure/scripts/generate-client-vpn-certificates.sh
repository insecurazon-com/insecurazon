#!/bin/bash

# Client VPN Certificate Generation Script
# This script generates certificates for AWS Client VPN and uploads them to ACM

set -e

# Configuration
CERT_DIR="./client-vpn-certificates"
REGION="${AWS_REGION:-us-east-1}"
ORGANIZATION="${VPN_ORG:-YourOrganization}"
ORGANIZATIONAL_UNIT="${VPN_OU:-IT}"
COUNTRY="${VPN_COUNTRY:-US}"
STATE="${VPN_STATE:-State}"
CITY="${VPN_CITY:-City}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 AWS Client VPN Certificate Generator${NC}"
echo "=========================================="

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    if ! command -v openssl &> /dev/null; then
        echo -e "${RED}❌ OpenSSL is required but not installed${NC}"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is required but not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Dependencies checked${NC}"
}

# Create certificate directory
create_cert_directory() {
    echo -e "${YELLOW}Creating certificate directory...${NC}"
    mkdir -p "$CERT_DIR"
    cd "$CERT_DIR"
    echo -e "${GREEN}✅ Directory created: $CERT_DIR${NC}"
}

# Generate CA certificate and key
generate_ca() {
    echo -e "${YELLOW}Generating CA certificate and key...${NC}"
    
    # Generate CA private key
    openssl genrsa -out ca.key 2048
    
    # Generate CA certificate
    openssl req -new -x509 -days 365 -key ca.key -out ca.crt \
        -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=VPN-CA"
    
    echo -e "${GREEN}✅ CA certificate generated${NC}"
}

# Generate server certificate
generate_server_cert() {
    echo -e "${YELLOW}Generating server certificate...${NC}"
    
    # Generate server private key
    openssl genrsa -out server.key 2048
    
    # Generate server certificate signing request
    openssl req -new -key server.key -out server.csr \
        -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=VPN-Server"
    
    # Generate server certificate signed by CA
    openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
    
    echo -e "${GREEN}✅ Server certificate generated${NC}"
}

# Generate client certificate
generate_client_cert() {
    echo -e "${YELLOW}Generating client certificate...${NC}"
    
    # Generate client private key
    openssl genrsa -out client.key 2048
    
    # Generate client certificate signing request
    openssl req -new -key client.key -out client.csr \
        -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=VPN-Client"
    
    # Generate client certificate signed by CA
    openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt
    
    echo -e "${GREEN}✅ Client certificate generated${NC}"
}

# Upload certificates to ACM
upload_to_acm() {
    echo -e "${YELLOW}Uploading certificates to AWS Certificate Manager...${NC}"
    
    # Upload server certificate
    echo "Uploading server certificate..."
    SERVER_CERT_ARN=$(aws acm import-certificate \
        --certificate file://server.crt \
        --certificate-chain file://ca.crt \
        --private-key file://server.key \
        --region "$REGION" \
        --query 'CertificateArn' \
        --output text)
    
    # Upload CA certificate (for client authentication)
    echo "Uploading CA certificate for client authentication..."
    CLIENT_CA_ARN=$(aws acm import-certificate \
        --certificate file://ca.crt \
        --private-key file://ca.key \
        --region "$REGION" \
        --query 'CertificateArn' \
        --output text)
    
    echo -e "${GREEN}✅ Certificates uploaded to ACM${NC}"
    echo -e "${BLUE}Server Certificate ARN: $SERVER_CERT_ARN${NC}"
    echo -e "${BLUE}Client CA ARN: $CLIENT_CA_ARN${NC}"
}

# Store certificates in SSM Parameter Store
store_in_ssm() {
    echo -e "${YELLOW}Storing certificates in SSM Parameter Store...${NC}"
    
    aws ssm put-parameter \
        --name "/client-vpn/certificates/ca-cert" \
        --value "$(cat ca.crt)" \
        --type "SecureString" \
        --description "Client VPN CA Certificate" \
        --overwrite \
        --region "$REGION" > /dev/null
    
    aws ssm put-parameter \
        --name "/client-vpn/certificates/ca-key" \
        --value "$(cat ca.key)" \
        --type "SecureString" \
        --description "Client VPN CA Private Key" \
        --overwrite \
        --region "$REGION" > /dev/null
    
    aws ssm put-parameter \
        --name "/client-vpn/certificates/client-cert" \
        --value "$(cat client.crt)" \
        --type "SecureString" \
        --description "Client VPN Client Certificate" \
        --overwrite \
        --region "$REGION" > /dev/null
    
    aws ssm put-parameter \
        --name "/client-vpn/certificates/client-key" \
        --value "$(cat client.key)" \
        --type "SecureString" \
        --description "Client VPN Client Private Key" \
        --overwrite \
        --region "$REGION" > /dev/null
    
    echo -e "${GREEN}✅ Certificates stored in SSM Parameter Store${NC}"
}

# Generate Terraform configuration snippet
generate_terraform_config() {
    echo -e "${YELLOW}Generating Terraform configuration...${NC}"
    
    cat > ../client-vpn-config.tf << EOF
# Generated Client VPN Configuration
# Add this to your main Terraform configuration

client_vpn_config = {
  enabled = true
  
  # Network settings
  client_cidr_block = "10.200.0.0/16"  # Adjust as needed
  vpc_name = "your-vpc-name"            # Replace with your VPC name
  subnet_names = ["private-subnet-1", "private-subnet-2"]  # Replace with your subnet names
  
  # Authentication using generated certificates
  authentication_type = "certificate-authentication"
  server_certificate_arn = "$SERVER_CERT_ARN"
  client_certificate_arn = "$CLIENT_CA_ARN"
  
  # VPN settings
  dns_servers = ["10.0.0.2"]  # Adjust as needed
  split_tunnel = true
  vpn_port = 443
  transport_protocol = "udp"
  
  # Authorization rules
  authorization_rules = [
    {
      target_network_cidr = "10.0.0.0/8"
      description = "Access to private networks"
    }
  ]
  
  # Enable Transit Gateway integration
  connect_to_transit_gateway = true
}
EOF
    
    echo -e "${GREEN}✅ Terraform configuration saved to ../client-vpn-config.tf${NC}"
}

# Create client configuration helper script
create_client_helper() {
    cat > prepare-client-config.sh << 'EOF'
#!/bin/bash

# Client VPN Configuration Helper
# Run this script after deploying the infrastructure to prepare the client configuration

set -e

ENDPOINT_ID="$1"
REGION="${AWS_REGION:-us-east-1}"

if [ -z "$ENDPOINT_ID" ]; then
    echo "Usage: $0 <client-vpn-endpoint-id>"
    echo "Example: $0 cvpn-endpoint-1234567890abcdef0"
    exit 1
fi

echo "🔧 Preparing Client VPN configuration..."

# Download client configuration
echo "Downloading client configuration..."
aws ec2 export-client-vpn-client-configuration \
    --client-vpn-endpoint-id "$ENDPOINT_ID" \
    --region "$REGION" \
    --output text > client-vpn-config.ovpn

# Get client certificate and key from SSM
echo "Retrieving client certificate from SSM..."
aws ssm get-parameter \
    --name "/client-vpn/certificates/client-cert" \
    --with-decryption \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text > client.crt

aws ssm get-parameter \
    --name "/client-vpn/certificates/client-key" \
    --with-decryption \
    --region "$REGION" \
    --query 'Parameter.Value' \
    --output text > client.key

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

echo "✅ Client configuration ready: client-vpn-config.ovpn"
echo ""
echo "To connect:"
echo "  macOS/Linux: sudo openvpn --config client-vpn-config.ovpn"
echo "  Windows: Import client-vpn-config.ovpn into OpenVPN Connect"
EOF

    chmod +x prepare-client-config.sh
    echo -e "${GREEN}✅ Client helper script created: prepare-client-config.sh${NC}"
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}🎉 Certificate generation completed successfully!${NC}"
    echo "=============================================="
    echo -e "${BLUE}Files created:${NC}"
    echo "  📁 $CERT_DIR/"
    echo "    🔑 ca.crt, ca.key (CA certificate and key)"
    echo "    🖥️  server.crt, server.key (Server certificate and key)"
    echo "    👤 client.crt, client.key (Client certificate and key)"
    echo "    🛠️  prepare-client-config.sh (Client config helper)"
    echo "  📄 client-vpn-config.tf (Terraform configuration)"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Copy the configuration from client-vpn-config.tf to your Terraform files"
    echo "  2. Update the vpc_name and subnet_names in the configuration"
    echo "  3. Run 'terraform apply' to deploy the Client VPN"
    echo "  4. Use prepare-client-config.sh to prepare your client configuration"
    echo ""
    echo -e "${YELLOW}Certificate ARNs (for manual configuration):${NC}"
    echo "  Server Certificate ARN: $SERVER_CERT_ARN"
    echo "  Client CA ARN: $CLIENT_CA_ARN"
}

# Main execution
main() {
    echo -e "${BLUE}Starting certificate generation...${NC}"
    
    check_dependencies
    create_cert_directory
    generate_ca
    generate_server_cert
    generate_client_cert
    upload_to_acm
    store_in_ssm
    generate_terraform_config
    create_client_helper
    print_summary
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --region)
            REGION="$2"
            shift 2
            ;;
        --org)
            ORGANIZATION="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --region REGION    AWS region (default: us-east-1)"
            echo "  --org ORG         Organization name (default: YourOrganization)"
            echo "  --help            Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  AWS_REGION        AWS region"
            echo "  VPN_ORG          Organization name"
            echo "  VPN_OU           Organizational unit"
            echo "  VPN_COUNTRY      Country code"
            echo "  VPN_STATE        State/Province"
            echo "  VPN_CITY         City"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main 