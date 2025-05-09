resource "aws_vpc_endpoint" "s3" {
  count = var.vpc_config.s3_endpoint.add_endpoint ? 1 : 0
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Name = "s3-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "kms" {
  count = var.vpc_config.kms_endpoint.add_endpoint ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type   = var.vpc_config.kms_endpoint.vpc_endpoint_type

  subnet_ids          = [
    for subnet in var.vpc_config.subnets : 
    aws_subnet.this[subnet.name].id if subnet.allow_kms == true
  ]
  security_group_ids  = [aws_security_group.allow_kms.id]
  private_dns_enabled = var.vpc_config.kms_endpoint.private_dns_enabled

  tags = {
    Name = "kms-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {  
  count = var.vpc_config.secretsmanager_endpoint.add_endpoint ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = var.vpc_config.secretsmanager_endpoint.vpc_endpoint_type

  subnet_ids          = [
    for subnet in var.vpc_config.subnets : 
    aws_subnet.this[subnet.name].id if subnet.allow_secretsmanager == true
  ]
  security_group_ids  = [aws_security_group.allow_secretsmanager.id]

  private_dns_enabled = var.vpc_config.secretsmanager_endpoint.private_dns_enabled

  tags = {
    Name = "secretsmanager-vpc-endpoint"
  }
}