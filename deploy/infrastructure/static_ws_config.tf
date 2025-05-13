locals {
  static_website_config = {
    bucket_name = "static-website-bucket-insecurazon"
    force_destroy = true
    versioning_enabled = true
    cors_rules = [
      {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "HEAD"]
        allowed_origins = ["*"]
        expose_headers = ["ETag"]
        max_age_seconds = 3600
      }
    ]
    index_document = "index.html"
    error_document = "error.html"
    cloudfront_enabled = true
    cloudfront_ipv6_enabled = true
    tags = {
      Environment = "dev"
    }
  }
}