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
    main_route_table_id = string
    subnet_ids = list(string)
    name = string
    main_route_table = bool
    main_route_table_id = string
    routes = list(object({
      destination_cidr_block = string
      nat_gateway_id = string
      transit_gateway_id = string
      vpc_peering_connection_id = string
      gateway_id = string
    }))
    associated_endpoints = list(string)
  })
}

resource "aws_route_table" "this" {
  count = var.routing_config.main_route_table == false ? 1 : 0
  vpc_id = var.routing_config.vpc_id

  dynamic "route" {
    for_each = var.routing_config.routes
    content {
      cidr_block = route.value.destination_cidr_block
      nat_gateway_id = route.value.nat_gateway_id != "" ? route.value.nat_gateway_id : null
      transit_gateway_id = route.value.transit_gateway_id != "" ? route.value.transit_gateway_id : null
      vpc_peering_connection_id = route.value.vpc_peering_connection_id != "" ? route.value.vpc_peering_connection_id : null
      gateway_id = route.value.gateway_id != "" ? route.value.gateway_id : null
    }
  }

  tags = {
    Name = var.routing_config.name
  }
}

resource "aws_route" "this" {
  count = var.routing_config.main_route_table ? length(var.routing_config.routes) : 0
  route_table_id = var.routing_config.main_route_table_id
  destination_cidr_block = var.routing_config.routes[count.index].destination_cidr_block
  gateway_id = var.routing_config.routes[count.index].gateway_id != "" ? var.routing_config.routes[count.index].gateway_id : null
  transit_gateway_id = var.routing_config.routes[count.index].transit_gateway_id != "" ? var.routing_config.routes[count.index].transit_gateway_id : null
  vpc_peering_connection_id = var.routing_config.routes[count.index].vpc_peering_connection_id != "" ? var.routing_config.routes[count.index].vpc_peering_connection_id : null
  nat_gateway_id = var.routing_config.routes[count.index].nat_gateway_id != "" ? var.routing_config.routes[count.index].nat_gateway_id : null
}

resource "aws_route_table_association" "this" {
  count = length(var.routing_config.subnet_ids)
  subnet_id      = var.routing_config.subnet_ids[count.index]
  route_table_id = var.routing_config.main_route_table == true ? var.routing_config.main_route_table_id : aws_route_table.this[0].id
}

resource "aws_vpc_endpoint_route_table_association" "this" {
  count = length(var.routing_config.associated_endpoints)
  route_table_id = var.routing_config.main_route_table ? var.routing_config.main_route_table_id : var.routing_config.main_route_table_id
  vpc_endpoint_id = var.routing_config.associated_endpoints[count.index]
}


output "route_table" {
  value = aws_route_table.this
}
