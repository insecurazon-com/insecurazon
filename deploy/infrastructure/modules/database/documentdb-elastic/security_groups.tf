# Lambda security group
resource "aws_security_group" "lambda_sg" {
  name        = "${local.lambda_function_name}-sg"
  description = "Security group for DocumentDB user creator Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.lambda_function_name}-sg"
  })
}