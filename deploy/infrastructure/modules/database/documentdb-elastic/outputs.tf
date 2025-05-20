output "documentdb_elastic_config" {
  value = {
    cluster_endpoint = aws_docdbelastic_cluster.documentdb_elastic.endpoint
    cluster_id = aws_docdbelastic_cluster.documentdb_elastic.id
    cluster_arn = aws_docdbelastic_cluster.documentdb_elastic.arn
    password_secret_arn = aws_secretsmanager_secret.documentdb_password.arn
    password_secret_name = aws_secretsmanager_secret.documentdb_password.name
    app_user_secret_arns = { for k, v in var.application_users : v.username => aws_secretsmanager_secret.app_user_password[k].arn }
    app_user_secret_names = { for k, v in var.application_users : v.username => aws_secretsmanager_secret.app_user_password[k].name }
    lambda_function_name = aws_lambda_function.docdb_user_creator.function_name
    lambda_function_arn = aws_lambda_function.docdb_user_creator.arn
  }
}