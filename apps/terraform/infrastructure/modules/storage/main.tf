variable "module_depends_on" {
  description = "Module dependencies"
  type        = any
}

resource "aws_s3_bucket" "static_website" {
  depends_on = [var.module_depends_on]
  bucket        = var.static_website_config.bucket_name
  force_destroy = var.static_website_config.force_destroy

  tags = merge(
    {
      Name        = var.static_website_config.bucket_name
    },
    var.static_website_config.tags
  )
}

resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = var.static_website_config.index_document
  }

  error_document {
    key = var.static_website_config.error_document
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.static_website.id
  
  versioning_configuration {
    status = var.static_website_config.versioning_enabled ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  count  = length(var.static_website_config.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.static_website.id

  dynamic "cors_rule" {
    for_each = var.static_website_config.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.static_website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_public_access_block.public_access,
    aws_s3_bucket_ownership_controls.ownership,
  ]

  bucket = aws_s3_bucket.static_website.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

# Create CloudFront distribution for CDN
resource "aws_cloudfront_distribution" "static_website_cdn" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.static_website.website_endpoint
    origin_id   = "S3-${var.static_website_config.bucket_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = var.static_website_config.cloudfront_enabled
  is_ipv6_enabled     = var.static_website_config.cloudfront_ipv6_enabled
  default_root_object = var.static_website_config.index_document

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.static_website_config.bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(
    {
      Name        = "${var.static_website_config.bucket_name}-cdn"
    },
    var.static_website_config.tags
  )
}
