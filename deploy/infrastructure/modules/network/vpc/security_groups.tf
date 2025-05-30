resource "aws_security_group" "allow_kms" {
  name        = "allow-kms"
  description = "Allow KMS traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ 
      for subnet in var.vpc_config.subnets : 
      aws_subnet.this[subnet.name].cidr_block if subnet.allow_kms == true
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_kms"
  }
}

resource "aws_security_group" "allow_secretsmanager" {
  name        = "allow-secretsmanager"
  description = "Allow Secrets Manager traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ 
      for subnet in var.vpc_config.subnets : 
      aws_subnet.this[subnet.name].cidr_block if subnet.allow_secretsmanager == true
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_secretsmanager"
  }
}

resource "aws_security_group" "allow_sts" {
  name        = "allow-sts"
  description = "Allow STS traffic"
  vpc_id      = aws_vpc.this.id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ 
      for subnet in var.vpc_config.subnets : 
      aws_subnet.this[subnet.name].cidr_block if subnet.allow_sts == true
    ]
  }
}

resource "aws_security_group" "allow_internet_access" {
  name        = "allow-internet-access"
  description = "Allow Internet access"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_internet_access"
  }
}

