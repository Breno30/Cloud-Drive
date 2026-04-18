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
  description = "Optional custom domain name (host only, no scheme) for the Cognito Hosted UI (e.g. auth.example.com). Requires cognito_acm_certificate_arn. DNS records must be created separately."
}

variable "cognito_acm_certificate_arn" {
  type        = string
  default     = null
  description = "Optional ACM certificate ARN for the Cognito custom domain."
}

variable "name_suffix" {
  type = string
}
