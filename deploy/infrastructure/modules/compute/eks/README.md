# AWS EKS Terraform Module

This module creates an Amazon EKS (Elastic Kubernetes Service) cluster with associated resources including security groups, node groups, and Fargate profiles. IAM roles are expected to be provided from the IAM module.

## Features

- Creates an EKS cluster with configurable settings
- Supports both managed node groups and Fargate profiles
- Configures cluster logging, encryption, and networking
- Outputs kubeconfig for cluster access
- Uses IAM roles provided as inputs (separation of concerns)

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

module "eks" {
  source = "path/to/modules/compute/eks"

  eks = {
    cluster_name    = "my-eks-cluster"
    cluster_version = "1.32"
    vpc_id          = "vpc-12345678"
    subnet_ids      = ["subnet-12345678", "subnet-87654321"]
    
    # IAM roles from the IAM module
    cluster_role_arn = module.iam_eks.cluster_role_arn
    node_role_arn = module.iam_eks.node_role_arn
    fargate_pod_execution_role_arn = module.iam_eks.fargate_role_arn
    
    # Access configuration
    access = {
      private = true
      public  = false
      cidrs   = ["0.0.0.0/0"]
    }
    
    # CloudWatch logging configuration
    cloudwatch = {
      enabled = true
      retention_in_days = 90
    }
    log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    
    # Encryption configuration
    cluster_encryption_config = []
    
    # Node groups configuration
    node_groups = {
      default = {
        name           = "default-node-group"
        instance_types = ["t3.medium"]
        ami_type       = "AL2_x86_64"
        capacity_type  = "ON_DEMAND"
        disk_size      = 20
        min_size       = 1
        max_size       = 3
        desired_size   = 2
        subnet_ids     = null # Will use the module's subnet_ids if null
        labels         = { "role" = "worker" }
        taints         = []
      }
    }

    # Fargate profiles configuration
    fargate_profiles = {
      default = {
        name       = "default-fargate-profile"
        subnet_ids = null # Will use the module's subnet_ids if null
        selectors = [
          {
            namespace = "default"
            labels    = { "fargate" = "true" }
          }
        ]
      }
    }

    # Common tags
    tags = {
      Environment = "dev"
      Project     = "my-project"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| eks | EKS configuration | `object` | n/a | yes |
| default_cluster_version | Default Kubernetes version to use if not specified in eks object | `string` | `"1.32"` | no |
| default_cluster_enabled_log_types | Default log types to enable if not specified in eks object | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |

## The `eks` object structure

The `eks` object supports the following attributes:

| Name | Description | Type | Required |
|------|-------------|------|----------|
| cluster_name | Name of the EKS cluster | `string` | yes |
| cluster_version | Kubernetes version to use for the EKS cluster | `string` | no |
| vpc_id | VPC ID where the EKS cluster will be deployed | `string` | yes |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` | yes |
| cluster_role_arn | ARN of the IAM role for the EKS cluster | `string` | yes |
| node_role_arn | ARN of the IAM role for the EKS node groups | `string` | yes |
| fargate_pod_execution_role_arn | ARN of the IAM role for Fargate pod execution | `string` | yes |
| access | Access configuration for the cluster | `object` | no |
| cloudwatch | CloudWatch configuration for the cluster | `object` | no |
| log_types | Log types to enable for the cluster | `list(string)` | no |
| cluster_encryption_config | Configuration block with encryption configuration for the cluster | `list(object)` | no |
| node_groups | Map of EKS managed node group definitions to create | `map(object)` | no |
| fargate_profiles | Map of Fargate Profile definitions to create | `map(object)` | no |
| tags | A map of tags to add to all resources | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| eks_config | Comprehensive EKS configuration object containing all cluster details |

The `eks_config` output object contains:

- `cluster_id`: The name/id of the EKS cluster
- `cluster_arn`: The Amazon Resource Name (ARN) of the cluster
- `cluster_endpoint`: The endpoint for the Kubernetes API server
- `cluster_certificate_authority_data`: Base64 encoded certificate data required to communicate with the cluster
- `cluster_security_group_id`: Security group ID attached to the EKS cluster
- `node_groups`: Map of EKS managed node groups created
- `fargate_profiles`: Map of EKS Fargate Profiles created
- `kubeconfig`: Kubectl configuration to connect to the cluster

## License

MIT 