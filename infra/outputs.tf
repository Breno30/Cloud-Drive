output "cloud_drive_bucket_name" {
  value = aws_s3_bucket.cloud_drive.bucket
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "frontend_origin" {
  value = local.frontend_origin
}

output "frontend_redirect_uri" {
  value = local.frontend_redirect_uri
}

output "frontend_cloudfront_domain" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.frontend.domain_name}/"
}
