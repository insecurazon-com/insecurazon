resource "aws_eip" "nat" {
  count = length(var.vpc_config.nat_gateway.subnet_names)
  domain = "vpc"

  tags = {
    Name = "${var.vpc_config.vpc_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  count = length(var.vpc_config.nat_gateway.subnet_names)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = [
    for subnet in aws_subnet.this : subnet.id
    if subnet.tags["Name"] == "${var.vpc_config.vpc_name}-${var.vpc_config.nat_gateway.subnet_names[count.index]}"
  ][0]

  tags = {
    Name = "${var.vpc_config.vpc_name}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

# Create route table entries for private subnets to use NAT Gateway
# resource "aws_route" "nat_gateway" {
#   for_each = {
#     for subnet in var.vpc_config.subnets : subnet.route_table_name => subnet
#     if !subnet.public && var.vpc_config.nat_gateway.add_nat_gateway
#   }

#   route_table_id         = aws_route_table.this[each.key].id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.this[0].id
# }
