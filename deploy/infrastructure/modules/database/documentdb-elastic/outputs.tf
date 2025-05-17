output "cluster_endpoint" {
  description = "The cluster endpoint"
  value       = aws_docdbelastic_cluster.documentdb_elastic.endpoint
}

output "cluster_id" {
  description = "The DocumentDB Elastic cluster ID"
  value       = aws_docdbelastic_cluster.documentdb_elastic.id
}

output "cluster_arn" {
  description = "The DocumentDB Elastic cluster ARN"
  value       = aws_docdbelastic_cluster.documentdb_elastic.arn
}

output "password_secret_arn" {
  description = "ARN of the secret containing the DocumentDB password"
  value       = aws_secretsmanager_secret.documentdb_password.arn
}

output "password_secret_name" {
  description = "Name of the secret containing the DocumentDB password"
  value       = aws_secretsmanager_secret.documentdb_password.name
}

output "app_user_secret_arns" {
  description = "Map of application usernames to their corresponding Secrets Manager ARNs"
  value       = { for k, v in var.application_users : v.username => aws_secretsmanager_secret.app_user_password[k].arn }
}

output "app_user_secret_names" {
  description = "Map of application usernames to their corresponding Secrets Manager names"
  value       = { for k, v in var.application_users : v.username => aws_secretsmanager_secret.app_user_password[k].name }
}

output "lambda_function_name" {
  description = "Name of the Lambda function that creates database users"
  value       = aws_lambda_function.docdb_user_creator.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function that creates database users"
  value       = aws_lambda_function.docdb_user_creator.arn
} 