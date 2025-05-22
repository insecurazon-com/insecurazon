locals {
  eks_config = {
    cluster_name = "eks-cluster"
    cluster_version = "1.32"
    vpc_id = module.network_config.vpc_config.main.vpc_config.vpc_id
    subnet_ids = [
      module.network_config.vpc_config.main.vpc_config.subnet.main-control-plane-1.id,
      module.network_config.vpc_config.main.vpc_config.subnet.main-control-plane-2.id,
      module.network_config.vpc_config.main.vpc_config.subnet.main-control-plane-3.id
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
    tags = {
      "Name" = "eks-cluster"
    }
  }
  argocd_config = {
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
