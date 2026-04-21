locals {
  frontend_custom_domain_name = "drive.${var.domain_name}"
  cognito_custom_domain_name  = "authdrive.${var.domain_name}"

  frontend_origin       = "https://${local.frontend_custom_domain_name}"
  frontend_redirect_uri = "${local.frontend_origin}/index.html"
}
