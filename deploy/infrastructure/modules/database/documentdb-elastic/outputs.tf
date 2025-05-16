output "cluster_endpoint" {
  description = "The cluster endpoint"
  value       = aws_docdb_cluster.documentdb_elastic.endpoint
}

output "cluster_id" {
  description = "The DocumentDB cluster ID"
  value       = aws_docdb_cluster.documentdb_elastic.id
}

output "cluster_resource_id" {
  description = "The DocumentDB cluster resource ID"
  value       = aws_docdb_cluster.documentdb_elastic.cluster_resource_id
}

output "password_secret_arn" {
  description = "ARN of the secret containing the DocumentDB password"
  value       = aws_secretsmanager_secret.documentdb_password.arn
}

output "password_secret_name" {
  description = "Name of the secret containing the DocumentDB password"
  value       = aws_secretsmanager_secret.documentdb_password.name
}

output "db_instances" {
  description = "List of DocumentDB instances in the cluster"
  value       = aws_docdb_cluster_instance.cluster_instances.*.id
} 