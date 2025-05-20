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


variable "lambda_config" {
  description = "Configuration for the Lambda function"
  type = object({
    function_name = string
    handler = string
    runtime = string
    vpc_id = string
    subnet_ids = list(string)
    api_gateway_name = string
  })
}
