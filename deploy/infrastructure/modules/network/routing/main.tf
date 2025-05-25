# resource "aws_route_table" "this" {
#   for_each = var.vpc_config.subnet
#   vpc_id = var.vpc_config.vpc_id

#   tags = {
#     Name = "${var.vpc_config.vpc_name}-${each.value.name}"
#   }
# }

# resource "aws_route_table_association" "this" {
#   for_each = var.vpc_config.subnet
#   subnet_id = each.value.id
#   route_table_id = aws_route_table.this[each.value.name].id
# }

# # Create route table entries for private subnets to use NAT Gateway
# resource "aws_route" "nat_gateway" {
#   for_each = var.vpc_config.subnet
#   route_table_id         = aws_route_table.this[each.value.name].id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = var.nat_gateway.id
# }

# output "route_table" {
#   value = {
#     for route_table in aws_route_table.this : route_table.id => {
#       id = route_table.id
#       arn = route_table.arn
#     }
#   }
# }

variable "routing_config" {
  type = object({
    vpc_id = string
    vpc_name = string
    subnet_id = string
    subnet_name = string
    routes = list(object({
      destination_cidr_block = string
      nat_gateway_id = string
      transit_gateway_id = string
      gateway_id = string
    }))
    associated_endpoints = list(string)
  })
}

resource "aws_route_table" "this" {
  vpc_id = var.routing_config.vpc_id

  dynamic "route" {
    for_each = var.routing_config.routes
    content {
      cidr_block = route.value.destination_cidr_block
      nat_gateway_id = route.value.nat_gateway_id != "" ? route.value.nat_gateway_id : null
      transit_gateway_id = route.value.transit_gateway_id != "" ? route.value.transit_gateway_id : null
      gateway_id = route.value.gateway_id != "" ? route.value.gateway_id : null
    }
  }

  tags = {
    Name = "${var.routing_config.vpc_name}-${var.routing_config.subnet_name}"
  }
}

resource "aws_route_table_association" "this" {
  subnet_id      = var.routing_config.subnet_id
  route_table_id = aws_route_table.this.id
}

resource "aws_vpc_endpoint_route_table_association" "this" {
  count = length(var.routing_config.associated_endpoints)
  route_table_id = aws_route_table.this.id
  vpc_endpoint_id = var.routing_config.associated_endpoints[count.index]
}
