variable "module_depends_on" {
  type    = any
  default = []
}

resource "aws_vpc_peering_connection" "this" {
  depends_on = [ var.module_depends_on ]
  vpc_id = var.peering_config.vpc_id
  peer_vpc_id = var.peering_config.peer_vpc_id
  tags = merge(var.peering_config.tags, {
    Name = var.peering_config.peering_name
  })
}

resource "aws_vpc_peering_connection_accepter" "this" {
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = merge(var.peering_config.tags, {
    Name = var.peering_config.peering_name
  })
}

output "peering_config" {
  value = {
    peering_name = var.peering_config.peering_name
    peering_id = aws_vpc_peering_connection.this.id
    vpc_peering_connection_id = aws_vpc_peering_connection.this.id
    vpc_peering_connection_accepter_id = aws_vpc_peering_connection_accepter.this.id
  }
}
