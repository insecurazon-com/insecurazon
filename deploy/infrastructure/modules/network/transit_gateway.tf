resource "aws_ec2_transit_gateway" "this" {
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  description = "Transit Gateway"
  tags = {
    Name = "transit-gateway"
  }
}

