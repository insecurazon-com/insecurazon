variable "documentdb_elastic_config" {
  description = "DocumentDB Elastic configuration"
  type        = object({
    cluster_identifier = string
    environment = string
    shard_count = number
    shard_capacity = number
    master_username = string
    application_users = map(object({
      username = string
      db_roles = list(object({
        db   = string
        role = string
      }))
    }))
    vpc_id = string
    subnet_ids = list(string)
    tags = map(string)
  })
}