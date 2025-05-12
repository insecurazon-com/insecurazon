variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "static_website_config" {
  description = "Static website configuration for the bucket"
  type = object({
    bucket_name = string
    force_destroy = bool
    versioning_enabled = bool
    cors_rules = list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = list(string)
      max_age_seconds = number
    }))
    index_document = string
    error_document = string
    cloudfront_enabled = bool
    cloudfront_ipv6_enabled = bool
    tags = map(string)
  })
}