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

variable "acm_certificate_arn" {
  type        = string
  description = "Optional acm certificate arn."
  default     = ""
}

variable "frontend_custom_domain_name" {
  type        = string
  description = "Optional custom domain name (host only, no scheme) for the frontend CloudFront distribution (e.g. app.example.com)."
  default     = ""

  validation {
    condition = (
      var.frontend_custom_domain_name == "" ||
      (
        !can(regex("://", var.frontend_custom_domain_name)) &&
        !can(regex("/", var.frontend_custom_domain_name)) &&
        !can(regex("\\s", var.frontend_custom_domain_name)) &&
        !can(regex("\\*", var.frontend_custom_domain_name)) &&
        can(regex("^([A-Za-z0-9-]+\\.)+[A-Za-z0-9-]+$", var.frontend_custom_domain_name))
      )
    )
    error_message = "frontend_custom_domain_name must be a hostname only (e.g. app.example.com), without scheme/path/whitespace/wildcards."
  }
}

variable "cognito_custom_domain_name" {
  type        = string
  description = "Optional custom domain name (host only) for Cognito Hosted UI (e.g. auth.example.com). DNS records must be created separately."
  default     = ""

  validation {
    condition = (
      var.cognito_custom_domain_name == "" ||
      (
        !can(regex("://", var.cognito_custom_domain_name)) &&
        !can(regex("/", var.cognito_custom_domain_name)) &&
        !can(regex("\\s", var.cognito_custom_domain_name)) &&
        !can(regex("\\*", var.cognito_custom_domain_name)) &&
        can(regex("^([A-Za-z0-9-]+\\.)+[A-Za-z0-9-]+$", var.cognito_custom_domain_name)) &&
        var.cognito_acm_certificate_arn != ""
      )
    )
    error_message = "cognito_custom_domain_name must be a hostname only (e.g. auth.example.com), without scheme/path/whitespace/wildcards, and requires cognito_acm_certificate_arn."
  }
}

variable "cognito_acm_certificate_arn" {
  type        = string
  description = "Optional ACM certificate ARN for the Cognito custom domain."
  default     = ""
}

variable "cognito_login_url" {
  type        = string
  description = "Optional custom Cognito Hosted UI base URL (e.g. https://auth.example.com)."
  default     = ""
}
