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
        add_endpoint = bool
        vpc_endpoint_type   = optional(string, "Interface")
        private_dns_enabled = bool
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
      nat_gateway = object({
        subnet_names = list(string)
      })
      subnets       = list(object({
        name              = string
        cidr              = string
        availability_zone = string
        allow_kms         = optional(bool, false)
        allow_secretsmanager = optional(bool, false)
      }))
    }))
  })
}

variable "peering_config" {
  description = "Map of peering configurations"
  type = map(object({
    peering_name = string
    vpc_name = string
    peer_vpc_name = string
    tags = map(string)
  }))
  default = {}
}

variable "routing_config" {
  description = "Map of routing configurations"
  type        = map(object({
    vpc_name = string
    name = string
    main_route_table = bool
    subnet_names = list(string)
    routes = list(object({
      destination_cidr_block = string
      gateway = string
    }))
    associated_endpoints = list(string)
  }))
}

variable "nat_routing_config" {
  description = "Additional routing configurations for NAT subnets"
  type        = list(object({
    vpc_name = string
    subnet_name = string
    routes = list(object({
      destination_cidr_block = string
      gateway = string
    }))
    associated_endpoints = list(string)
  }))
  default = []
}

variable "transit_gateway_config" {
  type = object({
    enabled = optional(bool, false)
    attachments = optional(map(object({
      vpc_name = string
      subnets = list(string)
      appliance_mode_support = string
    })), {})
    routes = optional(list(object({
      destination_cidr_block = string
      transit_gateway_attachment = string
    })), [])
  })
  default = { }
}

variable "client_vpn_config" {
  description = "Configuration for Client VPN"
  type = object({
    enabled = bool
    client_cidr_block = string
    authentication_type = string # "certificate-authentication" or "directory-service-authentication"
    
    # Certificate authentication settings (required if authentication_type is "certificate-authentication")
    server_certificate_arn = optional(string)
    client_certificate_arn = optional(string)
    
    # Directory service settings (required if authentication_type is "directory-service-authentication") 
    directory_id = optional(string)
    
    # Network settings
    vpc_name = string # Which VPC to attach the Client VPN to
    subnet_names = list(string) # Which subnets to associate with
    
    # VPN settings
    dns_servers = optional(list(string))
    split_tunnel = optional(bool, true)
    vpn_port = optional(number, 443)
    transport_protocol = optional(string, "udp")
    
    # Authorization settings
    authorization_rules = list(object({
      target_network_cidr = string
      description = optional(string)
    }))
    
    # Transit Gateway integration
    connect_to_transit_gateway = bool
  })
  default = {
    enabled = false
    client_cidr_block = "192.168.100.0/22"
    authentication_type = "certificate-authentication"
    vpc_name = ""
    subnet_names = []
    authorization_rules = []
    connect_to_transit_gateway = false
  }
}
