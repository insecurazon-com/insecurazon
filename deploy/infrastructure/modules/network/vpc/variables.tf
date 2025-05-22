variable "region" {
  description = "The AWS region"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the VPC."
  type        = string  
  default     = "platform.corp"
}

variable "vpc_config" {
  description = "The network variables"
  type        = object({ 
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
      add_endpoint        = bool
      private_dns_enabled = bool
      vpc_endpoint_type   = string
    })
    nat_gateway = object({
      subnet_names = list(string)
    })
    subnets       = list(object({
      name                 = string
      cidr                 = string
      availability_zone    = string
      default_route        = string
      allow_kms            = bool
      allow_secretsmanager = bool
    }))
  })
}

variable "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  type        = string
}
