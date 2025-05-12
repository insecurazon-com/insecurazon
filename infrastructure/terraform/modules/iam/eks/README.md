# AWS EKS IAM Terraform Module

This module creates IAM roles required for an EKS cluster, including roles for the cluster itself, worker nodes, and Fargate profiles.

## Features

- Creates the IAM role for the EKS control plane with required policies
- Creates the IAM role for EKS worker nodes with required policies
- Creates the IAM role for EKS Fargate profiles with required policies
- Provides outputs that can be used as inputs to the EKS module

## Usage

```hcl
module "iam_eks" {
  source = "path/to/modules/iam/eks"

  iam = {
    cluster_name = "my-eks-cluster"
    tags = {
      Environment = "dev"
      Project     = "my-project"
    }
  }
}

# The outputs from this module should be used as inputs to the EKS module
module "eks" {
  source = "path/to/modules/compute/eks"

  eks = {
    # ... other EKS module parameters ...
    cluster_role_arn = module.iam_eks.cluster_role_arn
    node_role_arn = module.iam_eks.node_role_arn
    fargate_pod_execution_role_arn = module.iam_eks.fargate_role_arn
    # ... more parameters ...
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| iam | IAM roles configuration for EKS | `object` | n/a | yes |

## The `iam` object structure

The `iam` object supports the following attributes:

| Name | Description | Type | Required |
|------|-------------|------|----------|
| cluster_name | Name of the EKS cluster | `string` | yes |
| tags | A map of tags to add to all resources | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_role_arn | ARN of the EKS cluster IAM role |
| cluster_role_name | Name of the EKS cluster IAM role |
| node_role_arn | ARN of the EKS node IAM role |
| node_role_name | Name of the EKS node IAM role |
| fargate_role_arn | ARN of the EKS Fargate IAM role |
| fargate_role_name | Name of the EKS Fargate IAM role |

## License

MIT 