locals {
  documentdb_elastic_config = {
    cluster_identifier    = "insecurazon-docdb-elastic"
    environment           = "prod"
    shard_count           = 1
    shard_capacity        = 2
    master_username       = "administrator"
    application_users     = {
      app_service = {
        username = "app_service"
        db_roles = [
          {
            db   = "insecurazon"
            role = "readWrite"
          },
          {
            db   = "admin"
            role = "read"
          }
        ]
      },
      read_user = {
        username = "read_user"
        db_roles = [
          {
            db   = "insecurazon"
            role = "read"
          }
        ]
      },
      write_user = {
        username = "write_user"
        db_roles = [
          {
            db   = "insecurazon"
            role = "readWrite"
          }
        ]
      },
      admin_read = {
        username = "admin_read"
        db_roles = [
          {
            db   = "admin"
            role = "read"
          }
        ]
      }
    }
    vpc_id = module.network_config.vpc_config.main.vpc_config.vpc_id
    subnet_ids = [
      module.network_config.vpc_config.main.vpc_config.subnet.main-data-1.id,
      module.network_config.vpc_config.main.vpc_config.subnet.main-data-2.id
    ]
    tags = {
      Environment = "prod"
      Project     = "insecurazon"
    }
  }
} 