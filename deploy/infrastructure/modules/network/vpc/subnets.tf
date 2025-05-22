resource "aws_subnet" "this" {
  for_each = { for subnet in var.vpc_config.subnets : subnet.name => subnet }
  vpc_id = aws_vpc.this.id
  cidr_block = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.vpc_config.vpc_name}-${each.value.name}"
  }
}

# resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
#   for_each = module.vpc 
#   subnet_ids = flatten([for subnet in each.value.vpc_config.subnet : subnet.id])
#   transit_gateway_id = aws_ec2_transit_gateway.this.id
#   vpc_id = each.value.vpc_config.vpc_id
# }