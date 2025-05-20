variable "module_depends_on" {
  description = "A list of modules that must be created before this one"
  type = list(any)
}

module "database_config" {
  module_depends_on = [ var.module_depends_on ]
  source = "./documentdb-elastic"
  
  environment           = var.documentdb_elastic_config.environment
  cluster_identifier    = var.documentdb_elastic_config.cluster_identifier
  shard_count           = var.documentdb_elastic_config.shard_count
  shard_capacity        = var.documentdb_elastic_config.shard_capacity
  master_username       = var.documentdb_elastic_config.master_username
  application_users     = var.documentdb_elastic_config.application_users
  
  vpc_id                = var.documentdb_elastic_config.vpc_id
  subnet_ids            = var.documentdb_elastic_config.subnet_ids
  
  tags = var.documentdb_elastic_config.tags
}

output "database_config" {
  value = module.database_config
}