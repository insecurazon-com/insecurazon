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
    igw = optional(object({
      add_igw = bool
    }), {
      add_igw = false
    })
    s3_endpoint = object({
      add_endpoint       = bool
    })
    kms_endpoint = optional(object({
      add_endpoint = bool
      vpc_endpoint_type   = optional(string, "Interface")
      private_dns_enabled = bool
    }), {
      add_endpoint = false
      private_dns_enabled = false
    })
    secretsmanager_endpoint = optional(object({
      add_endpoint        = bool
      private_dns_enabled = bool
      vpc_endpoint_type   = optional(string, "Interface")
    }), {
      add_endpoint        = false
      private_dns_enabled = false
    })
    sts_endpoint = optional(object({
      add_endpoint        = bool
      vpc_endpoint_type   = optional(string, "Interface")
    }), {
      add_endpoint        = false
    })
    nat_gateway = optional(object({
      subnet_names = list(string)
    }), {
      subnet_names = []
    })
    subnets       = list(object({
      name                 = string
      cidr                 = string
      availability_zone    = string
      allow_kms            = optional(bool, false)
      allow_secretsmanager = optional(bool, false)
    }))
  })
}

variable "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  type        = string
}
