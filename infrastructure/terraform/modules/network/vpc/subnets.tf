resource "aws_subnet" "this" {
  for_each = { for subnet in var.vpc_config.subnets : subnet.name => subnet }
  vpc_id = aws_vpc.this.id
  cidr_block = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.vpc_config.vpc_name}-${each.value.name}"
  }
}

resource "aws_route_table" "this" {
  for_each = {
    for subnet in var.vpc_config.subnets : subnet.route_table_name => subnet
  }
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = each.value.add_route_table ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = each.value.public ? aws_internet_gateway.this.id : null
    }
  }

  tags = {
    Name = "${var.vpc_config.vpc_name}-${each.value.route_table_name}"
  }
}

resource "aws_route_table_association" "this" {
  for_each = { for subnet in var.vpc_config.subnets : subnet.name => subnet }
  subnet_id = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.value.route_table_name].id
}
