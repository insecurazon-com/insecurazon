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
        subnets = [
          {
            public            = true
            name              = "public"
            cidr              = "10.0.1.0/24"
            availability_zone = "eu-central-1a"
            route_table_name  = "public"
            add_route_table   = true
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
        subnets = [
          {
            public            = false
            name              = "services-1"
            cidr              = "10.1.1.0/24"
            availability_zone = "eu-central-1a"
            route_table_name  = "services-1"
            add_route_table   = false
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            public            = false
            name              = "services-2"
            cidr              = "10.1.2.0/24"
            availability_zone = "eu-central-1b"
            route_table_name  = "services-2"
            add_route_table   = false
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            public            = false
            name              = "data-1"
            cidr              = "10.1.3.0/24"
            availability_zone = "eu-central-1a"
            route_table_name  = "data-1"
            add_route_table   = false
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            public            = false
            name              = "data-2"
            cidr              = "10.1.4.0/24"
            availability_zone = "eu-central-1b"
            route_table_name  = "data-2"
            add_route_table   = false
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            public            = false
            name              = "control-plane-1"
            cidr              = "10.1.11.0/24"
            availability_zone = "eu-central-1a"
            route_table_name  = "control-plane-1"
            add_route_table   = false
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            public            = false
            name              = "control-plane-2"
            cidr              = "10.1.12.0/24"
            availability_zone = "eu-central-1b"
            route_table_name  = "control-plane-2"
            add_route_table   = false
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            public            = false
            name              = "control-plane-3"
            cidr              = "10.1.13.0/24"
            availability_zone = "eu-central-1c"
            route_table_name  = "control-plane-3"
            add_route_table   = false
            allow_kms         = false
            allow_secretsmanager = false
          }
        ]
      }
    }
    peering = {
      egress_to_main = {
        vpc_name = "egress"
        peer_vpc_name = "main"
        tags = {}
      }
    }
  }
}