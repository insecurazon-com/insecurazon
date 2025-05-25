locals {
  transit_gateway_attachments = [
    for config in var.transit_gateway_config.attachments : {
      vpc_id = [ for vpc in module.vpc : vpc.vpc_config.vpc_id if vpc.vpc_config.vpc_name == config.vpc_name ][0]
      vpc_name = config.vpc_name
      subnet_ids = [ for subnet in module.vpc[config.vpc_name].vpc_config.subnet : subnet.id if contains(config.subnets, subnet.name) ]
      appliance_mode_support = config.appliance_mode_support
    }
  ]
}

resource "aws_ec2_transit_gateway" "this" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description = "Transit Gateway"
  tags = {
    Name = "transit-gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = length(local.transit_gateway_attachments)
  subnet_ids = local.transit_gateway_attachments[count.index].subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id = local.transit_gateway_attachments[count.index].vpc_id
  appliance_mode_support = local.transit_gateway_attachments[count.index].appliance_mode_support
  tags = {
    Name = "transit-gateway-attachment-${local.transit_gateway_attachments[count.index].vpc_name}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = "transit-gateway-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = {
    for attachment in aws_ec2_transit_gateway_vpc_attachment.this : attachment.tags.Name => attachment.id
  }
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id = each.value
}

# Add the missing route table associations
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = {
    for attachment in aws_ec2_transit_gateway_vpc_attachment.this : attachment.tags.Name => attachment.id
  }
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id = each.value
}

resource "aws_ec2_transit_gateway_route" "this" {
  count = length(var.transit_gateway_config.routes) 
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  destination_cidr_block = var.transit_gateway_config.routes[count.index].destination_cidr_block
  transit_gateway_attachment_id = [
    for attachment in aws_ec2_transit_gateway_vpc_attachment.this : attachment.id
    if attachment.tags.Name == "transit-gateway-attachment-${var.transit_gateway_config.routes[count.index].transit_gateway_attachment}"
  ][0]
}
