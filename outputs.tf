output "website_url" {
  description = "URL of the website"
  value       = "https://${module.static_site.cloudfront_domain}"
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.static_site.bucket_name
}

output "cloudfront_id" {
  description = "CloudFront distribution ID"
  value       = module.static_site.cloudfront_id
}