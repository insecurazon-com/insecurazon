variable "region" {
  description = "The AWS region"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the private hosted zone"
  type        = string
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
}
