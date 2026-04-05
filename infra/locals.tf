locals {
  frontend_bucket_name = "cloud-drive-frontend-${random_id.bucket_suffix.hex}"
  frontend_files       = fileset("${path.module}/../frontend", "*")
  frontend_asset_files = [for file in local.frontend_files : file if file != "config.js" && file != "config.example.js"]
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
  frontend_distribution_domain = aws_cloudfront_distribution.frontend.domain_name
  frontend_origin              = var.frontend_origin_override != "" ? var.frontend_origin_override : "https://${local.frontend_distribution_domain}"
  frontend_redirect_uri        = var.frontend_redirect_uri_override != "" ? var.frontend_redirect_uri_override : "${local.frontend_origin}/index.html"
}
