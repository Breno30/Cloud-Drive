variable "frontend_bucket_regional_domain_name" {
  type = string
}

variable "frontend_bucket_arn" {
  type = string
}

variable "frontend_bucket_id" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "frontend_custom_domain_name" {
  type    = string
  default = null
}

variable "acm_certificate_arn" {
  type    = string
  default = null
}

locals {
  custom_domain_name = (
    var.frontend_custom_domain_name != null && trimspace(var.frontend_custom_domain_name) != ""
  ) ? trimspace(var.frontend_custom_domain_name) : null

  certificate_arn = (
    var.acm_certificate_arn != null && trimspace(var.acm_certificate_arn) != ""
  ) ? trimspace(var.acm_certificate_arn) : null

  use_custom_domain = (
    local.custom_domain_name != null &&
    local.certificate_arn != null
  )
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "cloud-drive-frontend-oac-${var.name_suffix}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"

  # Only set aliases if custom domain is used
  aliases = local.use_custom_domain ? [local.custom_domain_name] : []

  origin {
    domain_name              = var.frontend_bucket_regional_domain_name
    origin_id                = "frontend-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = "frontend-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.use_custom_domain ? false : true

    acm_certificate_arn      = local.use_custom_domain ? local.certificate_arn : null
    ssl_support_method       = local.use_custom_domain ? "sni-only" : null
    minimum_protocol_version = local.use_custom_domain ? "TLSv1.2_2021" : null
  }
}

data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid     = "AllowCloudFrontRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${var.frontend_bucket_arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.frontend_bucket_id
  policy = data.aws_iam_policy_document.frontend_bucket_policy.json
}
