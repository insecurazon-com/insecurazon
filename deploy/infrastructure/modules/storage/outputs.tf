output "static_website_config" {
  description = "Static website configuration"
  value       = {
    bucket_name = aws_s3_bucket.static_website.id
    bucket_arn = aws_s3_bucket.static_website.arn
    website_endpoint = aws_s3_bucket_website_configuration.static_website.website_endpoint
    cloudfront_domain_name = aws_cloudfront_distribution.static_website_cdn.domain_name
    cloudfront_id = aws_cloudfront_distribution.static_website_cdn.id
  }
}