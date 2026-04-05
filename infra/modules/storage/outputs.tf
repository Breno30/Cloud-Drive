output "bucket_suffix" {
  value = random_id.bucket_suffix.hex
}

output "cloud_drive_bucket_name" {
  value = aws_s3_bucket.cloud_drive.bucket
}

output "cloud_drive_bucket_arn" {
  value = aws_s3_bucket.cloud_drive.arn
}

output "cloud_drive_bucket_id" {
  value = aws_s3_bucket.cloud_drive.id
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_id" {
  value = aws_s3_bucket.frontend.id
}

output "frontend_bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
