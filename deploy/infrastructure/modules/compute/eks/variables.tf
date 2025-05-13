variable "eks_config" {
  description = "EKS configuration"
  type = object({
    cluster_name = string
    cluster_version = string
    cluster_role_arn = string
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
    node_role_arn = string
    fargate_profiles = map(object({
      name = string
      subnet_ids = list(string)
      selectors = list(object({
        namespace = string
        labels = map(string)
      }))
    }))
    fargate_pod_execution_role_arn = string
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



