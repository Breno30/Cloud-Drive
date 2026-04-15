resource "aws_cognito_user_pool" "user_pool" {
  name = "app-user-pool-${var.name_suffix}"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

locals {
  frontend_redirect_base = regexreplace(var.frontend_redirect_uri, "/[^/]*$", "")
}

resource "aws_cognito_user_pool_client" "spa_client" {
  name         = "spa-client-${var.name_suffix}"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "phone"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = distinct([
    var.frontend_origin,
    local.frontend_redirect_base,
    var.frontend_redirect_uri,
  ])
  default_redirect_uri = var.frontend_redirect_uri
  logout_urls          = [var.frontend_redirect_uri]
}

resource "aws_cognito_user_pool_domain" "hosted_ui" {
  domain       = "cloud-drive-${var.name_suffix}"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "app-identity-pool-${var.name_suffix}"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.spa_client.id
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
    server_side_token_check = true
  }
}

resource "aws_iam_role" "identity_pool_authenticated" {
  name = "identity-pool-authenticated-role-${var.name_suffix}"

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
  name = "identity-pool-authenticated-s3-${var.name_suffix}"
  role = aws_iam_role.identity_pool_authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListOwnPrefix"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.cloud_drive_bucket_arn
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
        Resource = "${var.cloud_drive_bucket_arn}/users/$${cognito-identity.amazonaws.com:sub}/*"
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

resource "aws_cognito_user_pool_ui_customization" "spa" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  client_id    = aws_cognito_user_pool_client.spa_client.id
  css          = file(var.ui_css_file)
  image_file   = filebase64(var.ui_logo_file)
}
