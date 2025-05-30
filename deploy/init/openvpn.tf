variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
  # You'll need to create this key pair in AWS console or via CLI
}

variable "my_ip" {
  description = "Your current public IP for SSH access (CIDR format)"
  type        = string
  default     = "0.0.0.0/0"  # Allow from anywhere initially
  # Get your IP: curl ifconfig.me
  # Example: "203.0.113.1/32" or "0.0.0.0/0" for anywhere
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager Session Manager for SSH access (no public SSH needed)"
  type        = bool
  default     = true
}

variable "admin_access_cidr" {
  description = "CIDR block for admin access to web interface"
  type        = string
  default     = "0.0.0.0/0"  # You can restrict this to your ISP's range
}

variable "vpn_cidr" {
  description = "VPN client IP range"
  type        = string
  default     = "10.8.0.0/24"
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-24.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# Get default VPC (or create your own)
data "aws_vpc" "default" {
  default = true
}

# Create a subnet in the default VPC (or use existing)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for VPN Server
resource "aws_security_group" "vpn_server" {
  name = "vpn-server-sg"
  description      = "Security group for OpenVPN server"
  vpc_id          = data.aws_vpc.default.id

  # SSH access - conditional based on enable_ssm
  dynamic "ingress" {
    for_each = var.enable_ssm ? [] : [1]
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
      description = "SSH access - disable if using SSM"
    }
  }

  # OpenVPN default port
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN UDP traffic"
  }

  # Alternative OpenVPN port (TCP)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN TCP traffic - alternative port"
  }

  # HTTP for Let's Encrypt (optional)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for Lets Encrypt"
  }

  # HTTPS for web admin interface
  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = [var.admin_access_cidr]
    description = "OpenVPN web admin interface"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "vpn-server-sg"
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "vpn_server_role" {
  name = "vpn-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "vpn-server-role"
  }
}

# IAM Policy for VPN server (customize based on your needs)
resource "aws_iam_role_policy" "vpn_server_policy" {
  name = "vpn-server-policy"
  role = aws_iam_role.vpn_server_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # CloudWatch for logging
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          
          # EC2 for instance metadata
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeRegions",
          
          # S3 for backups (optional)
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          
          # Route53 for dynamic DNS (optional)
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListHostedZones",
          
          # Systems Manager for parameter store
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policy for CloudWatch agent (optional)
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.vpn_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach Systems Manager policy for Session Manager
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.vpn_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "vpn_server_profile" {
  name = "vpn-server-profile"
  role = aws_iam_role.vpn_server_role.name
}

# Elastic IP for static IP address
resource "aws_eip" "vpn_server" {
  domain = "vpc"
  
  tags = {
    Name = "vpn-server-eip"
  }
}

# User data script for OpenVPN installation
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    vpn_cidr = var.vpn_cidr
  }))
}

# EC2 Instance
resource "aws_instance" "vpn_server" {
  # ami                     = data.aws_ami.ubuntu.id
  ami                     = "ami-03250b0e01c28d196"
  instance_type          = "t2.micro"
  key_name               = var.key_pair_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.vpn_server.id]
  iam_instance_profile   = aws_iam_instance_profile.vpn_server_profile.name
  
  # Enable source/destination checking (disable for NAT functionality)
  source_dest_check = false
  
  user_data = local.user_data

  root_block_device {
    volume_type           = "gp3"
    volume_size          = 8
    delete_on_termination = true
    encrypted            = true
  }

  tags = {
    Name = "vpn-server"
    Type = "VPN"
  }

  # Ensure the instance is replaced if user data changes
  user_data_replace_on_change = true
}

# Associate Elastic IP with instance
resource "aws_eip_association" "vpn_server" {
  instance_id   = aws_instance.vpn_server.id
  allocation_id = aws_eip.vpn_server.id
}

# Outputs
output "vpn_server_public_ip" {
  description = "Public IP address of the VPN server"
  value       = aws_eip.vpn_server.public_ip
}

output "vpn_server_instance_id" {
  description = "Instance ID of the VPN server"
  value       = aws_instance.vpn_server.id
}

output "ssh_command" {
  description = "SSH command to connect to the VPN server (if SSH port is open)"
  value       = var.enable_ssm ? "Use SSM Session Manager instead" : "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_eip.vpn_server.public_ip}"
}

output "ssm_command" {
  description = "AWS Systems Manager Session Manager command"
  value       = var.enable_ssm ? "aws ssm start-session --target ${aws_instance.vpn_server.id}" : "SSM not enabled"
}

output "openvpn_admin_url" {
  description = "OpenVPN admin interface URL"
  value       = "https://${aws_eip.vpn_server.public_ip}:943/admin"
}

output "openvpn_user_portal" {
  description = "OpenVPN user portal for downloading configs"
  value       = "https://${aws_eip.vpn_server.public_ip}/"
}

output "vpn_server_dns" {
  description = "Use this IP in your VPN client configuration"
  value       = aws_eip.vpn_server.public_ip
}

output "security_group_id" {
  description = "Security Group ID for manual updates"
  value       = aws_security_group.vpn_server.id
}