output "files_bucket_name" {
  value = module.storage.cloud_drive_bucket_name
}

output "frontend_bucket_name" {
  value = module.storage.frontend_bucket_name
}

output "upload_url" {
  value = module.uploader.upload_url
}

output "frontend_cloudfront_url" {
  value = "https://${module.cdn.domain_name}/"
}