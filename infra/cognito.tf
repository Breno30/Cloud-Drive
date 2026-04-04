terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

variable "frontend_origin_override" {
  type        = string
  description = "Optional override for the frontend origin (scheme + host)."
  default     = ""
}

variable "frontend_redirect_uri_override" {
  type        = string
  description = "Optional override for the frontend OAuth redirect URI."
  default     = ""
}

locals {
  frontend_bucket_name  = "cloud-drive-frontend-${random_id.bucket_suffix.hex}"
  frontend_origin       = var.frontend_origin_override != "" ? var.frontend_origin_override : "https://${local.frontend_bucket_name}.s3.amazonaws.com"
  frontend_redirect_uri = var.frontend_redirect_uri_override != "" ? var.frontend_redirect_uri_override : "${local.frontend_origin}/index.html"
  frontend_files        = fileset("${path.module}/../frontend", "*")
  frontend_asset_files  = [for file in local.frontend_files : file if file != "config.js" && file != "config.example.js"]
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

resource "aws_cognito_user_pool" "user_pool" {
  name = "app-user-pool"

  # Use email as the only sign-in identifier.
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "spa_client" {
  name         = "spa-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  # SPA clients should not have a client secret
  generate_secret = false

  # Enable Hosted UI / OAuth
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "phone"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = [local.frontend_redirect_uri]
  logout_urls   = [local.frontend_redirect_uri]
}

resource "aws_cognito_user_pool_domain" "hosted_ui" {
  domain       = "cloud-drive"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "app-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.spa_client.id
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
    server_side_token_check = true
  }
}

resource "aws_iam_role" "identity_pool_authenticated" {
  name = "identity-pool-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "identity_pool_authenticated_s3" {
  name = "identity-pool-authenticated-s3"
  role = aws_iam_role.identity_pool_authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListOwnPrefix"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = aws_s3_bucket.cloud_drive.arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "users/$${cognito-identity.amazonaws.com:sub}/*"
            ]
          }
        }
      },
      {
        Sid    = "ObjectAccessOwnPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.cloud_drive.arn}/users/$${cognito-identity.amazonaws.com:sub}/*"
      }
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    authenticated = aws_iam_role.identity_pool_authenticated.arn
  }
}

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

  bucket       = aws_s3_bucket.frontend.id
  key          = each.value
  source       = "${path.module}/../frontend/${each.value}"
  etag         = filemd5("${path.module}/../frontend/${each.value}")
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
    redirect_uri       = local.frontend_redirect_uri
    client_id          = aws_cognito_user_pool_client.spa_client.id
    user_pool_id       = aws_cognito_user_pool.user_pool.id
    token_url          = "https://${aws_cognito_user_pool_domain.hosted_ui.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/token"
    login_url          = "https://${aws_cognito_user_pool_domain.hosted_ui.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
    identity_url       = "https://cognito-identity.${data.aws_region.current.name}.amazonaws.com/"
    identity_pool_id   = aws_cognito_identity_pool.identity_pool.id
    region             = data.aws_region.current.name
    bucket             = aws_s3_bucket.cloud_drive.bucket
    list_prefix_base   = "users"
    list_url           = ""
    aws_sdk_url        = "https://sdk.amazonaws.com/js/aws-sdk-2.1571.0.min.js"
    use_session_storage = true
    storage_quota_bytes = 10 * 1024 * 1024
  })
  content_type = lookup(local.frontend_content_types, ".js", "application/javascript; charset=utf-8")

  depends_on = [aws_s3_bucket_policy.frontend]
}

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
