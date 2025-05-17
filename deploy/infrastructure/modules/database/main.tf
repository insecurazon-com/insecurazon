module "database_config" {
  module_depends_on = [ module.network_config ]
  source = "./documentdb-elastic"
  
  environment           = var.documentdb_elastic_config.environment
  cluster_identifier    = var.documentdb_elastic_config.cluster_identifier
  shard_count           = var.documentdb_elastic_config.shard_count
  shard_capacity        = var.documentdb_elastic_config.shard_capacity
  master_username       = var.documentdb_elastic_config.master_username
  application_users     = var.documentdb_elastic_config.application_users
  
  vpc_id                = var.documentdb_elastic_config.vpc_id
  vpc_security_group_ids = var.documentdb_elastic_config.vpc_security_group_ids
  subnet_ids            = var.documentdb_elastic_config.subnet_ids
  
  tags = var.documentdb_elastic_config.tags
}