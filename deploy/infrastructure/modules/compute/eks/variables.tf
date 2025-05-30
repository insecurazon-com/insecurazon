variable "eks_config" {
  description = "EKS configuration"
  type = object({
    cluster_name = string
    cluster_version = string
    vpc_id = string
    subnet_ids = list(string)
    cluster_encryption_config = list(object({
      provider_key_arn = string
      resources = list(string)
    }))
    access = object({
      private = bool
      public = bool
      cidrs = list(string)
    })
    log_types = list(string)
    cloudwatch = object({
      enabled = bool
      retention_in_days = number
    })
    node_groups = map(object({
      name = string
      instance_types = list(string)
      ami_type = string
      capacity_type = string
      disk_size = number
      min_size = number
      max_size = number
      desired_size = number
      subnet_ids = list(string)
      labels = map(string)
      taints = list(map(string))
    }))
    fargate_profiles = map(object({
      name = string
      subnet_ids = list(string)
      selectors = list(object({
        namespace = string
        labels = map(string)
      }))
    }))
    tags = map(string)
  })
}

variable "default_cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "default_cluster_enabled_log_types" {
  description = "A list of the desired control plane logs to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "install_argocd" {
  description = "Whether to install ArgoCD on the cluster"
  type        = bool
  default     = true
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 900
}

variable "lambda_memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 512
}

variable "argocd_config" {
  description = "ArgoCD configuration"
  type = object({
    enabled = bool
    namespace = string
    version = string
    admin_password = string
    server = object({
      host = string
      port = number
      secure = bool
    })
    rbac = object({
      enabled = bool
      policy_csv = string
    })
    notifications = object({
      enabled = bool
      config = string
    })
    applications = list(object({
      name = string
      namespace = string
      source = object({
        repo_url = string
        path = string
        target_revision = string
      })
      destination = object({
        server = string
        namespace = string
      })
      sync_policy = object({
        automated = object({
          prune = bool
          self_heal = bool
        })
        sync_options = list(string)
      })
    }))
  })
  default = {
    enabled = true
    namespace = "argocd"
    version = "v3.0.2"
    admin_password = "admin"
    server = {
      host = "argocd.example.com"
      port = 443
      secure = true
    }
    rbac = {
      enabled = true
      policy_csv = ""
    }
    notifications = {
      enabled = false
      config = ""
    }
    applications = []
  }
}

variable "network_config" {
  description = "Network configuration from the network module"
  type = any  # Using 'any' to accept the complex network module output
}



