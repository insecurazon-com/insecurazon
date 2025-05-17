variable "module_depends_on" {
  type    = any
  default = null
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_identifier" {
  description = "The identifier for the DocumentDB Elastic cluster"
  type        = string
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "admin"
}

variable "application_users" {
  description = "Map of application users with their database access roles"
  type = map(object({
    username = string
    db_roles = list(object({
      db   = string
      role = string
    }))
  }))
  default = {}
}

variable "shard_capacity" {
  description = "The number of vCPUs assigned to each elastic cluster shard"
  type        = number
  default     = 2
}

variable "shard_count" {
  description = "The number of shards assigned to the elastic cluster"
  type        = number
  default     = 1
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "subnet_ids" {
  description = "List of VPC subnet IDs to place the elastic cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where the DocumentDB cluster and Lambda function will be deployed"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate with the cluster"
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS key ARN or ID for encrypting the elastic cluster"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 