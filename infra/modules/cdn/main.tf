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

  validation {
    condition = (
      var.acm_certificate_arn == null ||
      can(regex("^arn:aws(-[a-z]+)?:acm:[a-z0-9-]+:[0-9]{12}:certificate\\/.+$", var.acm_certificate_arn))
    )
    error_message = "acm_certificate_arn must look like a valid ACM certificate ARN."
  }
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

  aliases = var.frontend_custom_domain_name == null ? [] : [var.frontend_custom_domain_name]

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
    cloudfront_default_certificate = var.acm_certificate_arn == null
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn == null ? null : "sni-only"
    minimum_protocol_version       = var.acm_certificate_arn == null ? null : "TLSv1.2_2021"
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
