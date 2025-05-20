resource "aws_security_group" "lambda_security_group" {
  name = "lambda-security-group"
  description = "Security group for Lambda function"
  vpc_id = var.lambda_config.vpc_id

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
}
