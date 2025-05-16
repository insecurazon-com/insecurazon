locals {
  documentdb_elastic_config = {
    cluster_identifier    = "insecurazon-docdb-elastic"
    environment           = "prod"
    instance_count        = 1
    instance_class        = "db.t3.medium"
    deletion_protection   = true
    skip_final_snapshot   = false
    master_username       = "admin"
  }
} 