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

variable "network_config" {
  description = "Map of network configurations"
  type        = object({ 
    vpc = map(object({
      vpc_cidr      = string
      vpc_name      = string
      s3_endpoint = object({
        add_endpoint       = bool
      })
      kms_endpoint = object({
        add_endpoint = bool
        vpc_endpoint_type   = string
        private_dns_enabled = bool
      })
      secretsmanager_endpoint = object({
        add_endpoint = bool
        vpc_endpoint_type   = string
        private_dns_enabled = bool
      })
      subnets       = list(object({
        name              = string
        cidr              = string
        availability_zone = string
        route_table_name  = string
        add_route_table   = bool
        allow_kms         = bool
        allow_secretsmanager = bool
      }))
    }))
    peering = map(object({
      vpc_name = string
      peer_vpc_name = string
      tags = map(string)
    }))
  })
  default = {
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
        subnets = [
          {
            name              = "public"
            cidr              = "10.0.1.0/24"
            availability_zone = "eu-central-1a"
            route_table_name  = "public"
            add_route_table   = true
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "private"
            cidr              = "10.0.2.0/24"
            availability_zone = "eu-central-1a"
            route_table_name  = "private"
            add_route_table   = false
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
        subnets = [
          {
            name              = "external"
            cidr              = "10.1.1.0/24"
            availability_zone = "eu-central-1a"
            route_table_name  = "external"
            add_route_table   = true
            allow_kms         = false
            allow_secretsmanager = false
          },
          {
            name              = "internal"
            cidr              = "10.1.2.0/24"
            availability_zone = "eu-central-1a"
            route_table_name  = "internal"
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