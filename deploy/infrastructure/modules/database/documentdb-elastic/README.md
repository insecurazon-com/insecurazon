# DocumentDB Elastic Cluster Terraform Module

This module provisions an AWS DocumentDB Elastic Cluster and stores the database password in AWS Secrets Manager.

## Features

- Creates a DocumentDB Elastic Cluster
- Generates a random secure password
- Stores credentials in AWS Secrets Manager
- Configurable instance count and instance types
- Customizable backup and maintenance windows
- Configurable security groups and subnet groups

## Usage

```hcl
module "documentdb_elastic" {
  source = "./modules/database/documentdb-elastic"
  
  environment           = "prod"
  cluster_identifier    = "insecurazon-docdb"
  vpc_security_group_ids = ["sg-12345678"]
  db_subnet_group_name  = "database-subnet-group"
  
  # Optional parameters
  instance_count        = 2
  instance_class        = "db.t3.medium"
  master_username       = "admin"
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  preferred_maintenance_window = "sun:05:00-sun:07:00"
  skip_final_snapshot   = false
  deletion_protection   = true
  
  tags = {
    Environment = "prod"
    Project     = "insecurazon"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (e.g., dev, staging, prod) | string | n/a | yes |
| cluster_identifier | The identifier for the DocumentDB Elastic cluster | string | n/a | yes |
| master_username | Username for the master DB user | string | "admin" | no |
| instance_count | Number of instances in the cluster | number | 1 | no |
| instance_class | The instance class to use for the cluster instances | string | "db.t3.medium" | no |
| backup_retention_period | The days to retain backups for | number | 7 | no |
| preferred_backup_window | The daily time range during which automated backups are created | string | "07:00-09:00" | no |
| preferred_maintenance_window | The weekly time range during which system maintenance can occur | string | "sun:05:00-sun:07:00" | no |
| skip_final_snapshot | Determines whether a final DB snapshot is created before the DB cluster is deleted | bool | false | no |
| deletion_protection | If the DB instance should have deletion protection enabled | bool | true | no |
| vpc_security_group_ids | List of VPC security groups to associate with the cluster | list(string) | n/a | yes |
| db_subnet_group_name | A DB subnet group to associate with the cluster | string | n/a | yes |
| tags | A map of tags to add to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | The cluster endpoint |
| cluster_id | The DocumentDB cluster ID |
| cluster_resource_id | The DocumentDB cluster resource ID |
| password_secret_arn | ARN of the secret containing the DocumentDB password |
| password_secret_name | Name of the secret containing the DocumentDB password |
| db_instances | List of DocumentDB instances in the cluster | 