variable "frontend_redirect_uri" {
  type = string
}

variable "frontend_origin" {
  type = string
}

variable "cloud_drive_bucket_arn" {
  type = string
}

variable "ui_css_file" {
  type = string
}

variable "ui_logo_file" {
  type = string
}

variable "cognito_custom_domain_name" {
  type        = string
  default     = null
  description = "Custom domain name (host only, no scheme) for the Cognito Hosted UI (e.g. authdrive.example.com). DNS records must be created separately."
}

variable "cognito_acm_certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN for the Cognito custom domain."

  validation {
    condition = (
      (
        (var.cognito_custom_domain_name == null && var.cognito_acm_certificate_arn == null) ||
        (var.cognito_custom_domain_name != null && var.cognito_acm_certificate_arn != null)
      ) &&
      (
        var.cognito_acm_certificate_arn == null ||
        can(regex("^arn:aws(-[a-z]+)?:acm:[a-z0-9-]+:[0-9]{12}:certificate\\/.+$", var.cognito_acm_certificate_arn))
      )
    )
    error_message = "To use a Cognito custom domain, set both cognito_custom_domain_name and cognito_acm_certificate_arn. If set, cognito_acm_certificate_arn must look like a valid ACM certificate ARN."
  }
}

variable "name_suffix" {
  type = string
}
