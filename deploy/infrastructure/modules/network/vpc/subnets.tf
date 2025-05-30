resource "aws_subnet" "this" {
  for_each = { for subnet in var.vpc_config.subnets : subnet.name => subnet }
  vpc_id = aws_vpc.this.id
  cidr_block = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.vpc_config.vpc_name}-${each.value.name}"
  }
}
