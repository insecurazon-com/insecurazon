variable "module_depends_on" {
  type    = any
  default = []
}

resource "aws_vpc_peering_connection" "this" {
  depends_on = [ var.module_depends_on ]
  vpc_id = var.vpc_id
  peer_vpc_id = var.peer_vpc_id
  tags = var.tags
}

resource "aws_vpc_peering_connection_accepter" "this" {
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = var.tags
}

output "peering_config" {
  value = {
    vpc_id = aws_vpc_peering_connection.this.vpc_id
    peer_vpc_id = aws_vpc_peering_connection.this.peer_vpc_id
    vpc_peering_connection_id = aws_vpc_peering_connection.this.id
    vpc_peering_connection_accepter_id = aws_vpc_peering_connection_accepter.this.id
  }
}
