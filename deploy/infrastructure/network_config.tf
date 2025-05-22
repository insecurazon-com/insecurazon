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
            name              = "nat-1"
            cidr              = "10.0.3.0/24"
            availability_zone = "eu-central-1c"
            default_route     = "igw"
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "nat-2"
            cidr              = "10.0.4.0/24"
            availability_zone = "eu-central-1d"
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
            name              = "data-1"
            cidr              = "10.1.3.0/24"
            availability_zone = "eu-central-1a"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "data-2"
            cidr              = "10.1.4.0/24"
            availability_zone = "eu-central-1b"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "control-plane-1"
            cidr              = "10.1.11.0/24"
            availability_zone = "eu-central-1a"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "control-plane-2"
            cidr              = "10.1.12.0/24"
            availability_zone = "eu-central-1b"
            default_route     = ""
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "control-plane-3"
            cidr              = "10.1.13.0/24"
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
    }
  ]
}