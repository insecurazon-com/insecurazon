# DocumentDB Elastic Cluster Terraform Module

This module provisions an AWS DocumentDB Elastic Cluster and stores the database password in AWS Secrets Manager.

## Features

- Creates a DocumentDB Elastic Cluster
- Generates a random secure password
- Stores credentials in AWS Secrets Manager
- Configurable shard count and capacity
- Customizable maintenance window
- Configurable security groups and subnet configuration
- Support for application users with customizable database roles
- Lambda function to automatically create database users

## Usage

```hcl
module "documentdb_elastic" {
  source = "./modules/database/documentdb-elastic"
  
  environment           = "prod"
  cluster_identifier    = "insecurazon-docdb"
  vpc_id                = "vpc-12345678"
  vpc_security_group_ids = ["sg-12345678"]
  subnet_ids            = ["subnet-12345", "subnet-67890"]
  
  # Optional parameters
  shard_count           = 1
  shard_capacity        = 2
  master_username       = "admin"
  preferred_maintenance_window = "sun:05:00-sun:07:00"
  kms_key_id            = "arn:aws:kms:region:account-id:key/key-id"
  
  # Application users with granular role permissions
  application_users     = {
    app_service = {
      username = "app_service"
      db_roles = [
        {
          db   = "insecurazon"
          role = "readWrite"
        },
        {
          db   = "admin"
          role = "read"
        }
      ]
    }
    read_user = {
      username = "read_user"
      db_roles = [
        {
          db   = "insecurazon"
          role = "read"
        }
      ]
    }
    write_user = {
      username = "write_user"
      db_roles = [
        {
          db   = "insecurazon"
          role = "readWrite"
        }
      ]
    }
  }
  
  tags = {
    Environment = "prod"
    Project     = "insecurazon"
  }
}
```

## Application Users

The module generates a random password for each application user specified in the `application_users` map and stores these credentials in AWS Secrets Manager. A Lambda function is deployed that will create these users in the DocumentDB Elastic cluster after it's provisioned.

Each application user can have custom roles for different databases:

```hcl
application_users = {
  app_service = {
    username = "app_service"
    db_roles = [
      {
        db   = "insecurazon"  # Database name
        role = "readWrite"    # Role for this database
      },
      {
        db   = "admin"
        role = "read"
      }
    ]
  }
}
```

Available DocumentDB roles include:
- `read` - Read-only access to the specified database
- `readWrite` - Read and write access to the specified database
- `dbAdmin` - Administrative access to the specified database
- `userAdmin` - User administration for the specified database
- `clusterAdmin` - Cluster administration
- `dbOwner` - Database owner

The Lambda function will automatically apply these roles when creating the users.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (e.g., dev, staging, prod) | string | n/a | yes |
| cluster_identifier | The identifier for the DocumentDB Elastic cluster | string | n/a | yes |
| master_username | Username for the master DB user | string | "admin" | no |
| application_users | Map of application users with their database access roles | map(object({ username = string, db_roles = list(object({ db = string, role = string })) })) | {} | no |
| shard_count | The number of shards assigned to the elastic cluster | number | 1 | no |
| shard_capacity | The number of vCPUs assigned to each elastic cluster shard | number | 2 | no |
| preferred_maintenance_window | The weekly time range during which system maintenance can occur | string | "sun:05:00-sun:07:00" | no |
| vpc_id | The ID of the VPC where the DocumentDB cluster and Lambda function will be deployed | string | n/a | yes |
| subnet_ids | List of VPC subnet IDs to place the elastic cluster | list(string) | n/a | yes |
| vpc_security_group_ids | List of VPC security groups to associate with the cluster | list(string) | n/a | yes |
| kms_key_id | KMS key ARN or ID for encrypting the elastic cluster | string | null | no |
| tags | A map of tags to add to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | The cluster endpoint |
| cluster_id | The DocumentDB Elastic cluster ID |
| cluster_arn | The DocumentDB Elastic cluster ARN |
| password_secret_arn | ARN of the secret containing the DocumentDB password |
| password_secret_name | Name of the secret containing the DocumentDB password |
| app_user_secret_arns | Map of application usernames to their corresponding Secrets Manager ARNs |
| app_user_secret_names | Map of application usernames to their corresponding Secrets Manager names |
| lambda_function_name | Name of the Lambda function that creates database users |
| lambda_function_arn | ARN of the Lambda function that creates database users | 