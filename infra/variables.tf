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
