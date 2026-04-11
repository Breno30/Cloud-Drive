resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_suffix = random_id.bucket_suffix.hex
}

resource "aws_s3_bucket" "cloud_drive" {
  bucket = "cloud-drive-${local.bucket_suffix}"
}

resource "aws_s3_bucket" "frontend" {
  bucket = "cloud-drive-frontend-${local.bucket_suffix}"
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
