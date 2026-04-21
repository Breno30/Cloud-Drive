locals {
  frontend_custom_domain_name = var.domain_name == null ? null : "drive.${var.domain_name}"
  cognito_custom_domain_name  = var.domain_name == null ? null : "authdrive.${var.domain_name}"

  frontend_origin = (
    var.domain_name == null
    ? "https://${module.cdn.domain_name}"
    : "https://${local.frontend_custom_domain_name}"
  )
  frontend_redirect_uri = "${local.frontend_origin}/index.html"
}
