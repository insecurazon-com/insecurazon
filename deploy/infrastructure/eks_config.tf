locals {
  eks_config = {
    cluster_name = "eks-cluster"
    cluster_version = "1.32"
    cluster_role_arn = module.iam_config.iam_eks_config.cluster_role_arn
    vpc_id = module.network_config.vpc_config.main.vpc_config.vpc_id
    subnet_ids = [
      module.network_config.vpc_config.main.vpc_config.subnet.main-control-plane-1.id,
      module.network_config.vpc_config.main.vpc_config.subnet.main-control-plane-2.id
    ]
    cluster_encryption_config = []
    access = {
      private = true
      public = false
      cidrs = ["0.0.0.0/0"]
    }
    log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    cloudwatch = {
      enabled = false
      retention_in_days = 7
    }
    node_groups = {}
    node_role_arn = module.iam_config.iam_eks_config.node_role_arn
    fargate_profiles = {
      "default" = {
        name = "default"
        subnet_ids = [
          module.network_config.vpc_config.main.vpc_config.subnet.main-services-1.id,
          module.network_config.vpc_config.main.vpc_config.subnet.main-services-2.id
        ]
        selectors = [
          {
            namespace = "default"
            labels = {
              "app" = "default"
            }
          }
        ]
      }
    }
    fargate_pod_execution_role_arn = module.iam_config.iam_eks_config.fargate_role_arn
    tags = {
      "Name" = "eks-cluster"
    }
  }
}
