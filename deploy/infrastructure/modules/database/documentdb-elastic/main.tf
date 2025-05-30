resource "random_password" "documentdb_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  depends_on       = [var.module_depends_on]
}

resource "random_id" "secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret" "documentdb_password" {
  name        = "documentdb-elastic-password-${var.environment}-${random_id.secret_suffix.hex}"
  description = "DocumentDB Elastic Cluster password for ${var.environment} environment"
}

resource "aws_secretsmanager_secret_version" "documentdb_password" {
  secret_id     = aws_secretsmanager_secret.documentdb_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.documentdb_password.result
    connection_string = "mongodb://${var.master_username}:${random_password.documentdb_password.result}@${aws_docdbelastic_cluster.documentdb_elastic.endpoint}:27017/?tls=true&retryWrites=false"
  })
}

resource "random_password" "app_user_password" {
  for_each         = var.application_users
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  depends_on       = [var.module_depends_on]
}

resource "aws_secretsmanager_secret" "app_user_password" {
  for_each    = var.application_users
  name        = "documentdb-elastic-app-user-${each.value.username}-${var.environment}-${random_id.secret_suffix.hex}"
  description = "DocumentDB Elastic Cluster application user ${each.value.username} password for ${var.environment} environment"
}

resource "aws_secretsmanager_secret_version" "app_user_password" {
  for_each      = var.application_users
  secret_id     = aws_secretsmanager_secret.app_user_password[each.key].id
  secret_string = jsonencode({
    username = each.value.username
    password = random_password.app_user_password[each.key].result
    db_roles = each.value.db_roles
    connection_string = "mongodb://${each.value.username}:${random_password.app_user_password[each.key].result}@${aws_docdbelastic_cluster.documentdb_elastic.endpoint}:27017/?tls=true&retryWrites=false"
  })
}

# Note: Since DocumentDB Elastic doesn't have a direct Terraform resource for creating users,
# we'll provide the passwords in Secrets Manager so they can be used in a post-deployment script
# or through application code to create the users using the admin credentials.

resource "aws_docdbelastic_cluster" "documentdb_elastic" {
  name                      = var.cluster_identifier
  admin_user_name           = var.master_username
  admin_user_password       = random_password.documentdb_password.result
  auth_type                 = "PLAIN_TEXT"
  shard_capacity            = var.shard_capacity
  shard_count               = var.shard_count
  preferred_maintenance_window = var.preferred_maintenance_window
  subnet_ids                = var.subnet_ids
  vpc_security_group_ids    = [ aws_security_group.lambda_sg.id ]
  kms_key_id                = var.kms_key_id
  
  tags = var.tags
} 