variable "region" {
  description = "The AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "domain_name" {
  description = "The domain name for the private hosted zone"
  type        = string
  default     = "platform.corp"
}

locals {
  network_config = {
    vpc = {
      egress = {
        vpc_cidr = "10.0.0.0/16"
        vpc_name = "egress"
        s3_endpoint = {
          add_endpoint       = false
        }
        kms_endpoint = {
          add_endpoint        = false
          vpc_endpoint_type   = "Interface"
          private_dns_enabled = true
        }
        secretsmanager_endpoint = {
          add_endpoint        = false
          vpc_endpoint_type   = "Interface"
          private_dns_enabled = true
        }
        igw = {
          add_igw = true
        }
        nat_gateway = {
          subnet_names = ["nat-1", "nat-2"]
        }
        subnets = [
          {
            name              = "public-1"
            cidr              = "10.0.1.0/24"
            availability_zone = "eu-central-1a"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "public-2"
            cidr              = "10.0.2.0/24"
            availability_zone = "eu-central-1b"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "public-3"
            cidr              = "10.0.3.0/24"
            availability_zone = "eu-central-1c"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "nat-1"
            cidr              = "10.0.11.0/24"
            availability_zone = "eu-central-1a"
            default_route     = "igw"
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "nat-2"
            cidr              = "10.0.12.0/24"
            availability_zone = "eu-central-1b"
            default_route     = "igw"
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "nat-3"
            cidr              = "10.0.13.0/24"
            availability_zone = "eu-central-1c"
            default_route     = "igw"
            allow_kms         = false
            allow_secretsmanager = false
          }
        ]
      }
      main = {
        vpc_cidr = "10.1.0.0/16"
        vpc_name = "main"
        s3_endpoint = {
          add_endpoint       = false
        }
        kms_endpoint = {
          add_endpoint        = false
          vpc_endpoint_type   = "Interface"
          private_dns_enabled = true
        }
        secretsmanager_endpoint = {
          add_endpoint        = false
          vpc_endpoint_type   = "Interface"
          private_dns_enabled = true
        }
        igw = {
          add_igw = false
        }
        nat_gateway = {
          subnet_names = []
        }
        subnets = [
          {
            name              = "services-1"
            cidr              = "10.1.1.0/24"
            availability_zone = "eu-central-1a"
            default_route     = "tgw"
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "services-2"
            cidr              = "10.1.2.0/24"
            availability_zone = "eu-central-1b"
            default_route     = "tgw"
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "services-3"
            cidr              = "10.1.3.0/24"
            availability_zone = "eu-central-1c"
            default_route     = "tgw"
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "data-1"
            cidr              = "10.1.11.0/24"
            availability_zone = "eu-central-1a"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "data-2"
            cidr              = "10.1.12.0/24"
            availability_zone = "eu-central-1b"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "data-3"
            cidr              = "10.1.13.0/24"
            availability_zone = "eu-central-1c"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "control-plane-1"
            cidr              = "10.1.21.0/24"
            availability_zone = "eu-central-1a"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "control-plane-2"
            cidr              = "10.1.22.0/24"
            availability_zone = "eu-central-1b"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "control-plane-3"
            cidr              = "10.1.23.0/24"
            availability_zone = "eu-central-1c"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          }
        ]
      }
    }
  }
  routing_config = [
    {
      vpc_name = "egress"
      subnet_name = "public-1"
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "internet_gateway"
        }
      ]
      associated_endpoints = []
    },
    {
      vpc_name = "egress"
      subnet_name = "public-2"
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "internet_gateway"
        }
      ]
      associated_endpoints = []
    },
    {
      vpc_name = "egress"
      subnet_name = "public-3"
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "internet_gateway"
        }
      ]
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "services-1"
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "transit_gateway"
        }
      ]
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "services-2"
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "transit_gateway"
        }
      ]
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "services-3"
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "transit_gateway"
        }
      ]
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "data-1"
      routes = []
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "data-2"
      routes = []
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "data-3"
      routes = []
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "control-plane-1"
      routes = []
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "control-plane-2"
      routes = []
      associated_endpoints = []
    },
    {
      vpc_name = "main"
      subnet_name = "control-plane-3"
      routes = []
      associated_endpoints = []
    },
    # Add routing configuration for NAT subnets in egress VPC
    # These subnets receive traffic from Transit Gateway and need to route it to NAT Gateway
    {
      vpc_name = "egress"
      subnet_name = "nat-1"
      routes = [
        {
          destination_cidr_block = "10.1.0.0/16"
          gateway = "nat_gateway"
        }
      ]
      associated_endpoints = []
    },
    {
      vpc_name = "egress"
      subnet_name = "nat-2"
      routes = [
        {
          destination_cidr_block = "10.1.0.0/16"
          gateway = "nat_gateway"
        }
      ]
      associated_endpoints = []
    }
  ]
  transit_gateway_config = {
    attachments = {
      main = {
        vpc_name = "main"
        subnets = ["main-services-1", "main-services-2", "main-services-3"]
        appliance_mode_support = "enable"
      },
      egress = {
        vpc_name = "egress"
        subnets = ["egress-nat-1", "egress-nat-2", "egress-nat-3"]
        appliance_mode_support = "enable"
      }
    }
    routes = [
      {
        destination_cidr_block = "0.0.0.0/0"
        transit_gateway_attachment = "egress"
      }
    ]
  }
  client_vpn_config = {
    enabled = true
    client_cidr_block = "10.200.0.0/16"
    vpc_name = "main"
    subnet_names = ["main-services-1", "main-services-2", "main-services-3"]
    
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
}
