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
      main = {
        vpc_cidr = "10.1.0.0/16"
        vpc_name = "main"
        s3_endpoint = {
          add_endpoint       = true
        }
        kms_endpoint = {
          add_endpoint        = true
          private_dns_enabled = true
        }
        secretsmanager_endpoint = {
          add_endpoint        = true
          private_dns_enabled = true
        }
        igw = {
          add_igw = true
        }
        nat_gateway = {
          subnet_names = [ "nat-1", "nat-2", "nat-3" ]
        }
        subnets = [
          {
            name              = "public-1"
            cidr              = "10.1.11.0/24"
            availability_zone = "eu-central-1a"
          },
          {
            name              = "public-2"
            cidr              = "10.1.21.0/24"
            availability_zone = "eu-central-1b"
          },
          {
            name              = "public-3"
            cidr              = "10.1.31.0/24"
            availability_zone = "eu-central-1c"
          },
          {
            name              = "services-1"
            cidr              = "10.1.12.0/24"
            availability_zone = "eu-central-1a"
            allow_kms         = true
            allow_secretsmanager = true
          },
          {
            name              = "services-2"
            cidr              = "10.1.22.0/24"
            availability_zone = "eu-central-1b"
            allow_kms         = true
            allow_secretsmanager = true
          },
          {
            name              = "services-3"
            cidr              = "10.1.32.0/24"
            availability_zone = "eu-central-1c"
            allow_kms         = true
            allow_secretsmanager = true
          },
          {
            name              = "data-1"
            cidr              = "10.1.13.0/24"
            availability_zone = "eu-central-1a"
          },
          {
            name              = "data-2"
            cidr              = "10.1.23.0/24"
            availability_zone = "eu-central-1b"
          },
          {
            name              = "data-3"
            cidr              = "10.1.33.0/24"
            availability_zone = "eu-central-1c"
          },
          {
            name              = "control-plane-1"
            cidr              = "10.1.14.0/24"
            availability_zone = "eu-central-1a"
          },
          {
            name              = "control-plane-2"
            cidr              = "10.1.24.0/24"
            availability_zone = "eu-central-1b"
          },
          {
            name              = "control-plane-3"
            cidr              = "10.1.34.0/24"
            availability_zone = "eu-central-1c"
          },
          {
            name              = "nat-1"
            cidr              = "10.1.15.0/24"
            availability_zone = "eu-central-1a"
          },
          {
            name              = "nat-2"
            cidr              = "10.1.25.0/24"
            availability_zone = "eu-central-1b"
          },
          {
            name              = "nat-3"
            cidr              = "10.1.35.0/24"
            availability_zone = "eu-central-1c"
          }
        ]
      }
    }
  }

  routing_config = {
    main-public = {
      vpc_name = "main"
      name = "main-public"
      main_route_table = true
      subnet_names = ["main-public-1", "main-public-2", "main-public-3"]
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "internet_gateway"
        }
      ]
      associated_endpoints = []
    }
    main-services-1 = {
      vpc_name = "main"
      name = "main-services-1"
      main_route_table = false
      subnet_names = ["main-services-1"]
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "nat_gateway:main-nat-1"
        }
      ]
      associated_endpoints = []
    },
    main-services-2 = {
      vpc_name = "main"
      name = "main-services-2"
      main_route_table = false
      subnet_names = ["main-services-2"]
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "nat_gateway:main-nat-2"
        }
      ]
      associated_endpoints = []
    },
    main-services-3 = {
      vpc_name = "main"
      name = "main-services-3"
      main_route_table = false
      subnet_names = ["main-services-3"]
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "nat_gateway:main-nat-3"
        }
      ]
      associated_endpoints = []
    },
    main-control-plane-1 = {
      vpc_name = "main"
      name = "main-control-plane-1"
      main_route_table = false
      subnet_names = ["main-control-plane-1"]
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "nat_gateway:main-nat-1"
        }
      ]
      associated_endpoints = []
    },
    main-control-plane-2 = {
      vpc_name = "main"
      name = "main-control-plane-2"
      main_route_table = false
      subnet_names = ["main-control-plane-2"]
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "nat_gateway:main-nat-2"
        }
      ]
      associated_endpoints = []
    },
    main-control-plane-3 = {
      vpc_name = "main"
      name = "main-control-plane-3"
      main_route_table = false
      subnet_names = ["main-control-plane-3"]
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          gateway = "nat_gateway:main-nat-3"
        }
      ]
      associated_endpoints = []
    }
  }

  transit_gateway_config = {
    enabled = false
    attachments = {
      main = {
        vpc_name = "main"
        subnets = ["main-services-1", "main-services-2", "main-services-3"]
        appliance_mode_support = "disable"
      },
      egress = {
        vpc_name = "egress"
        subnets = ["egress-public-1", "egress-public-2", "egress-public-3"]
        appliance_mode_support = "disable"
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
    enabled = false
    client_cidr_block = "10.200.0.0/16"
    vpc_name = "main"
    subnet_names = ["main-services-1", "main-services-2", "main-services-3"]
    split_tunnel = true
    
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
