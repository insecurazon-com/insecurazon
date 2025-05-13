# Static Website Hosting Terraform Module

This module creates the necessary AWS resources to host and serve static web content to the internet. It provides:

- S3 bucket configured for website hosting
- CloudFront distribution for CDN
- Appropriate bucket policies and configurations

## Usage

```hcl
module "static_website" {
  source = "path/to/modules/storage"

  bucket_name       = "my-static-website-bucket"
  environment       = "production"
  versioning_enabled = true
  
  cors_rules = [{
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }]
  
  tags = {
    Project = "MyWebsite"
  }
}
```

## Required Variables

- `bucket_name` - Name of the S3 bucket to create
- `environment` - Environment name (dev, staging, prod)

## Optional Variables

- `tags` - Map of tags to apply to resources
- `force_destroy` - Allow the bucket to be destroyed even if it contains objects (default: false)
- `versioning_enabled` - Enable versioning for the bucket (default: false)
- `cors_rules` - CORS configuration for the bucket
- `region` - AWS region (default: us-east-1)

## Outputs

- `bucket_name` - Name of the created S3 bucket
- `bucket_arn` - ARN of the S3 bucket
- `website_endpoint` - S3 website endpoint URL
- `cloudfront_domain_name` - CloudFront distribution domain name

## Notes

- This module sets up public access for the bucket to serve website content
- CloudFront is configured with default settings; adjust as needed for your use case 