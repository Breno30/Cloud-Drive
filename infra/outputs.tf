output "cloud_drive_bucket_name" {
  value = module.storage.cloud_drive_bucket_name
}

output "frontend_bucket_name" {
  value = module.storage.frontend_bucket_name
}

output "frontend_origin" {
  value = local.frontend_origin
}

output "frontend_redirect_uri" {
  value = local.frontend_redirect_uri
}

output "frontend_cloudfront_domain" {
  value = module.cdn.domain_name
}

output "frontend_cloudfront_url" {
  value = "https://${module.cdn.domain_name}/"
}

output "upload_url" {
  value = module.uploader.upload_url
}
