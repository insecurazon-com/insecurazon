variable "module_depends_on" {
  type    = any
  default = []
}

resource "aws_vpc" "this" {
  depends_on           = [ var.module_depends_on ]
  cidr_block           = var.vpc_config.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_config.vpc_name
  }
}

resource "aws_vpc_dhcp_options" "this" {
  domain_name         = var.domain_name
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "${var.vpc_config.vpc_name}-main-dhcp-options"
  }
}

resource "aws_internet_gateway" "this" {
  count = var.vpc_config.igw.add_igw ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_config.vpc_name}-igw"
  }
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this.id
}

output "vpc_config" {
  value = {
    vpc_id = aws_vpc.this.id
    vpc_name = aws_vpc.this.tags.Name
    cidr_block = aws_vpc.this.cidr_block
    main_route_table_id = aws_vpc.this.main_route_table_id
    nat_gateways = {
      for i, nat_gw in aws_nat_gateway.this : nat_gw.tags.Name => {
        id = nat_gw.id
        name = nat_gw.tags.Name
        subnet_id = nat_gw.subnet_id
      }
    }
    internet_gateway = var.vpc_config.igw.add_igw ? {
      id = aws_internet_gateway.this[0].id
    } : null
    subnet = {
      for subnet in aws_subnet.this : subnet.tags.Name => {
        id = subnet.id
        name = subnet.tags.Name
        cidr_block = subnet.cidr_block
        arn = subnet.arn
        availability_zone = subnet.availability_zone
      }
    }
  }
}