data "archive_file" "uploader" {
  type        = "zip"
  source_file = "${path.module}/lambda/uploader.py"
  output_path = "${path.module}/.build/uploader.zip"
}

resource "aws_iam_role" "uploader" {
  name = "cloud-drive-uploader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "uploader" {
  name = "cloud-drive-uploader-policy"
  role = aws_iam_role.uploader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-identity:GetId"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.cloud_drive_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = ["users/*"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.cloud_drive_bucket_arn}/users/*"
      }
    ]
  })
}

resource "aws_lambda_function" "uploader" {
  function_name = "cloud-drive-uploader"
  role          = aws_iam_role.uploader.arn
  handler       = "uploader.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.uploader.output_path
  source_code_hash = data.archive_file.uploader.output_base64sha256

  environment {
    variables = {
      BUCKET           = var.cloud_drive_bucket_name
      REGION           = var.region
      USER_POOL_ID     = var.user_pool_id
      IDENTITY_POOL_ID = var.identity_pool_id
      QUOTA_BYTES      = var.quota_bytes
      ALLOWED_ORIGIN   = "*"
    }
  }
}

resource "aws_lambda_function_url" "uploader" {
  function_name      = aws_lambda_function.uploader.arn
  authorization_type = "NONE"

  cors {
    allow_origins     = ["*"]
    allow_methods     = ["POST", "OPTIONS"]
    allow_headers     = ["authorization", "content-type", "x-file-name"]
    max_age           = 300
    allow_credentials = false
  }
}

resource "aws_lambda_permission" "uploader_url" {
  statement_id           = "AllowPublicLambdaUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.uploader.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
