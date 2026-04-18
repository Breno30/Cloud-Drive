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

variable "cognito_login_url" {
  type        = string
  description = "Optional custom Cognito Hosted UI base URL (e.g. https://auth.example.com)."
  default     = ""
}
