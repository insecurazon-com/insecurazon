# infrastructure/init/github-actions.tf
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "74f3a68f16524f15424927704c9506f55a9316bd"
  ]

  tags = {
    Name = "GitHubActions"
  }
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:insecurazon-com/insecurazon:*", 
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "GitHubActions-DeploymentRole"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json

  tags = {
    Name = "GitHubActions-DeploymentRole"
  }
}

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "github_actions_eks" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Custom policy for S3, CloudFront, Lambda, EC2, IAM, etc.
resource "aws_iam_role_policy" "github_actions_custom" {
  name = "GitHubActionsCustomPolicy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "cloudfront:*",
          "lambda:UpdateFunctionCode",
          "lambda:PublishVersion",
          "lambda:UpdateAlias",
          "eks:DescribeCluster",
          "eks:ListClusters",
          # EC2 permissions
          "ec2:*",
          # IAM permissions
          "iam:GetRole",
          "iam:ListRoles",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:TagRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "terraform:*"
        ]
        Resource = "arn:aws:s3:::${var.terraform_state_bucket}/*"
      }
    ]
  })
}