locals {
  frontend_distribution_domain = module.cdn.domain_name
  frontend_origin              = var.frontend_origin_override != "" ? var.frontend_origin_override : "https://${local.frontend_distribution_domain}"
  frontend_redirect_uri        = var.frontend_redirect_uri_override != "" ? var.frontend_redirect_uri_override : "${local.frontend_origin}/index.html"
}
