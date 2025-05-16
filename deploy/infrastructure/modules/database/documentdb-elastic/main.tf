resource "random_password" "documentdb_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  depends_on       = [var.module_depends_on]
}

resource "aws_secretsmanager_secret" "documentdb_password" {
  name        = "documentdb-elastic-password-${var.environment}"
  description = "DocumentDB Elastic Cluster password for ${var.environment} environment"
}

resource "aws_secretsmanager_secret_version" "documentdb_password" {
  secret_id     = aws_secretsmanager_secret.documentdb_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.documentdb_password.result
  })
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.instance_count
  identifier         = "${var.cluster_identifier}-${count.index}"
  cluster_identifier = aws_docdb_cluster.documentdb_elastic.id
  instance_class     = var.instance_class
  tags               = var.tags
}

resource "aws_docdb_cluster" "documentdb_elastic" {
  cluster_identifier        = var.cluster_identifier
  engine                    = "docdb-elastic"
  master_username           = var.master_username
  master_password           = random_password.documentdb_password.result
  backup_retention_period   = var.backup_retention_period
  preferred_backup_window   = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_identifier}-final-snapshot"
  deletion_protection       = var.deletion_protection
  vpc_security_group_ids    = var.vpc_security_group_ids
  db_subnet_group_name      = var.db_subnet_group_name
  
  tags = var.tags
} 