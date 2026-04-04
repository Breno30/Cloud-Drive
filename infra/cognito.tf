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

  callback_urls = ["https://local-drive.brenodonascimento.com/"]
  logout_urls   = ["https://local-drive.brenodonascimento.com/"]
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
    allowed_origins = ["https://local-drive.brenodonascimento.com"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
