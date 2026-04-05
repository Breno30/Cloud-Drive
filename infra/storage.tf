resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "cloud_drive" {
  bucket = "cloud-drive-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_cors_configuration" "cloud_drive" {
  bucket = aws_s3_bucket.cloud_drive.id

  cors_rule {
    allowed_origins = [local.frontend_origin]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "frontend" {
  bucket = local.frontend_bucket_name
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "frontend_public_read" {
  statement {
    sid     = "AllowPublicRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.frontend.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_public_read.json
}

resource "aws_s3_object" "frontend_assets" {
  for_each = toset(local.frontend_asset_files)

  bucket = aws_s3_bucket.frontend.id
  key    = each.value
  source = "${path.module}/../frontend/${each.value}"
  etag   = filemd5("${path.module}/../frontend/${each.value}")
  content_type = lookup(
    local.frontend_content_types,
    lower(try(regex("\\.[^.]+$", each.value), "")),
    "application/octet-stream"
  )

  depends_on = [aws_s3_bucket_policy.frontend]
}

resource "aws_s3_object" "frontend_config" {
  bucket = aws_s3_bucket.frontend.id
  key    = "config.js"
  content = templatefile("${path.module}/templates/config.js.tftpl", {
    redirect_uri        = local.frontend_redirect_uri
    client_id           = aws_cognito_user_pool_client.spa_client.id
    user_pool_id        = aws_cognito_user_pool.user_pool.id
    token_url           = "https://${aws_cognito_user_pool_domain.hosted_ui.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/token"
    login_url           = "https://${aws_cognito_user_pool_domain.hosted_ui.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
    identity_url        = "https://cognito-identity.${data.aws_region.current.name}.amazonaws.com/"
    identity_pool_id    = aws_cognito_identity_pool.identity_pool.id
    region              = data.aws_region.current.name
    bucket              = aws_s3_bucket.cloud_drive.bucket
    list_prefix_base    = "users"
    list_url            = ""
    aws_sdk_url         = "https://sdk.amazonaws.com/js/aws-sdk-2.1571.0.min.js"
    use_session_storage = true
    storage_quota_bytes = 10 * 1024 * 1024
  })
  content_type = lookup(local.frontend_content_types, ".js", "application/javascript; charset=utf-8")

  depends_on = [aws_s3_bucket_policy.frontend]
}
