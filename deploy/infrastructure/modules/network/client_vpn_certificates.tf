# Client VPN Certificate Generation using Terraform TLS Provider

# Generate CA private key
resource "tls_private_key" "ca" {
  count     = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate CA certificate
resource "tls_self_signed_cert" "ca" {
  count           = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  private_key_pem = tls_private_key.ca[0].private_key_pem

  subject {
    common_name         = "VPN-CA"
    organization        = "YourOrganization"
    organizational_unit = "IT"
    country             = "US"
    province            = "State"
    locality            = "City"
  }

  validity_period_hours = 8760 # 1 year

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# Generate server private key
resource "tls_private_key" "server" {
  count     = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate server certificate signing request
resource "tls_cert_request" "server" {
  count           = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  private_key_pem = tls_private_key.server[0].private_key_pem

  subject {
    common_name         = "VPN-Server"
    organization        = "YourOrganization"
    organizational_unit = "IT"
    country             = "US"
    province            = "State"
    locality            = "City"
  }

  dns_names = ["vpn.example.com"]
}

# Generate server certificate signed by CA
resource "tls_locally_signed_cert" "server" {
  count              = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  cert_request_pem   = tls_cert_request.server[0].cert_request_pem
  ca_private_key_pem = tls_private_key.ca[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[0].cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Generate client private key
resource "tls_private_key" "client" {
  count     = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate client certificate signing request
resource "tls_cert_request" "client" {
  count           = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  private_key_pem = tls_private_key.client[0].private_key_pem

  subject {
    common_name         = "VPN-Client"
    organization        = "YourOrganization"
    organizational_unit = "IT"
    country             = "US"
    province            = "State"
    locality            = "City"
  }
}

# Generate client certificate signed by CA
resource "tls_locally_signed_cert" "client" {
  count              = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  cert_request_pem   = tls_cert_request.client[0].cert_request_pem
  ca_private_key_pem = tls_private_key.ca[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[0].cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# Upload server certificate to ACM
resource "aws_acm_certificate" "server" {
  count             = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  private_key       = tls_private_key.server[0].private_key_pem
  certificate_body  = tls_locally_signed_cert.server[0].cert_pem
  certificate_chain = tls_self_signed_cert.ca[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "client-vpn-server-certificate"
    Type = "server"
  }
}

# Upload CA certificate to ACM (for client authentication)
resource "aws_acm_certificate" "client_ca" {
  count            = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.client_certificate_arn == null ? 1 : 0
  private_key      = tls_private_key.ca[0].private_key_pem
  certificate_body = tls_self_signed_cert.ca[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "client-vpn-client-ca-certificate"
    Type = "client-ca"
  }
}

# Store certificates in AWS Systems Manager Parameter Store for easy retrieval
resource "aws_ssm_parameter" "ca_cert" {
  count       = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  name        = "/client-vpn/certificates/ca-cert"
  description = "Client VPN CA Certificate"
  type        = "SecureString"
  value       = tls_self_signed_cert.ca[0].cert_pem

  tags = {
    Name = "client-vpn-ca-cert"
  }
}

resource "aws_ssm_parameter" "ca_key" {
  count       = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  name        = "/client-vpn/certificates/ca-key"
  description = "Client VPN CA Private Key"
  type        = "SecureString"
  value       = tls_private_key.ca[0].private_key_pem

  tags = {
    Name = "client-vpn-ca-key"
  }
}

resource "aws_ssm_parameter" "client_cert" {
  count       = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  name        = "/client-vpn/certificates/client-cert"
  description = "Client VPN Client Certificate"
  type        = "SecureString"
  value       = tls_locally_signed_cert.client[0].cert_pem

  tags = {
    Name = "client-vpn-client-cert"
  }
}

resource "aws_ssm_parameter" "client_key" {
  count       = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" && var.client_vpn_config.server_certificate_arn == null ? 1 : 0
  name        = "/client-vpn/certificates/client-key"
  description = "Client VPN Client Private Key"
  type        = "SecureString"
  value       = tls_private_key.client[0].private_key_pem

  tags = {
    Name = "client-vpn-client-key"
  }
}

# Local values for certificate ARNs (either generated or provided)
locals {
  server_certificate_arn = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" ? (
    var.client_vpn_config.server_certificate_arn != null ? 
    var.client_vpn_config.server_certificate_arn : 
    aws_acm_certificate.server[0].arn
  ) : null
  
  client_certificate_arn = var.client_vpn_config.enabled && var.client_vpn_config.authentication_type == "certificate-authentication" ? (
    var.client_vpn_config.client_certificate_arn != null ? 
    var.client_vpn_config.client_certificate_arn : 
    aws_acm_certificate.client_ca[0].arn
  ) : null
} 