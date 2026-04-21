resource "aws_s3_bucket_cors_configuration" "cloud_drive" {
  bucket = var.cloud_drive_bucket_id

  cors_rule {
    allowed_origins = [var.frontend_origin]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

locals {
  frontend_files       = fileset(var.frontend_dir, "**")
  frontend_asset_files = [for file in local.frontend_files : file if file != "config.js" && file != "config.example.js"]
  cognito_login_url = (
    can(regex("\\.", var.cognito_user_pool_domain))
    ? "https://${var.cognito_user_pool_domain}"
    : "https://${var.cognito_user_pool_domain}.auth.${var.region}.amazoncognito.com"
  )
  frontend_content_types = {
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".ico"  = "image/x-icon"
  }
}

resource "aws_s3_object" "frontend_assets" {
  for_each = toset(local.frontend_asset_files)

  bucket = var.frontend_bucket_id
  key    = each.value
  source = "${var.frontend_dir}/${each.value}"
  etag   = filemd5("${var.frontend_dir}/${each.value}")
  content_type = lookup(
    local.frontend_content_types,
    lower(try(regex("\\.[^.]+$", each.value), "")),
    "application/octet-stream"
  )
}

resource "aws_s3_object" "frontend_config" {
  bucket = var.frontend_bucket_id
  key    = "config.js"
  content = templatefile("${path.module}/templates/config.js.tftpl", {
    redirect_uri        = var.frontend_redirect_uri
    client_id           = var.cognito_client_id
    user_pool_id        = var.cognito_user_pool_id
    token_url           = "${local.cognito_login_url}/oauth2/token"
    login_url           = local.cognito_login_url
    identity_url        = "https://cognito-identity.${var.region}.amazonaws.com/"
    identity_pool_id    = var.cognito_identity_pool_id
    region              = var.region
    bucket              = var.cloud_drive_bucket_name
    list_prefix_base    = "users"
    list_url            = ""
    aws_sdk_url         = "https://sdk.amazonaws.com/js/aws-sdk-2.1571.0.min.js"
    use_session_storage = true
    storage_quota_bytes = 10 * 1024 * 1024
    upload_url          = var.upload_url
  })
  content_type = lookup(local.frontend_content_types, ".js", "application/javascript; charset=utf-8")
}
