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
      igw = object({
        add_igw = bool
      })
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
      nat_gateway = object({
        subnet_names = list(string)
      })
      subnets       = list(object({
        name              = string
        cidr              = string
        availability_zone = string
        default_route     = string
        allow_kms         = bool
        allow_secretsmanager = bool
      }))
    }))
  })
}

variable "routing_config" {
  description = "Map of routing configurations"
  type        = list(object({
    vpc_name = string
    subnet_name = string
    routes = list(object({
      destination_cidr_block = string
      gateway = string
    }))
    associated_endpoints = list(string)
  }))
}