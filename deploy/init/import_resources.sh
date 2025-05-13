#!/bin/bash
set -e

# Variables
BUCKET_NAME="insecurazon-terraform-state-bucket"
ROLE_NAME="GitHubActions-DeploymentRole"
POLICY_NAME="GitHubActionsCustomPolicy"

echo "Initializing Terraform..."
terraform init

echo "Importing S3 bucket..."
terraform import aws_s3_bucket.terraform_state $BUCKET_NAME

echo "Importing S3 bucket configurations..."
terraform import aws_s3_bucket_versioning.terraform_state_versioning $BUCKET_NAME
terraform import aws_s3_bucket_server_side_encryption_configuration.terraform_state_encryption $BUCKET_NAME
terraform import aws_s3_bucket_public_access_block.terraform_state_pab $BUCKET_NAME
terraform import aws_s3_bucket_lifecycle_configuration.terraform_state_lifecycle $BUCKET_NAME

echo "Getting OIDC provider ARN..."
OIDC_ARN=$(aws iam list-open-id-connect-providers | grep -o 'arn:aws:iam::[0-9]*:oidc-provider/token.actions.githubusercontent.com')

echo "Importing OIDC provider..."
terraform import aws_iam_openid_connect_provider.github $OIDC_ARN

echo "Importing IAM role..."
terraform import aws_iam_role.github_actions $ROLE_NAME

echo "Importing IAM policies..."
terraform import aws_iam_role_policy.github_actions_custom $ROLE_NAME:$POLICY_NAME
terraform import aws_iam_role_policy_attachment.github_actions_ecr $ROLE_NAME/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
terraform import aws_iam_role_policy_attachment.github_actions_eks $ROLE_NAME/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

echo "Running terraform plan to verify imports..."
terraform plan

echo "Import process completed!" 