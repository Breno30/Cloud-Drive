variable "domain_name" {
  type        = string
  default     = null
  description = "Base domain name (host only, no scheme). Terraform derives drive.<domain_name> and authdrive.<domain_name> automatically. DNS records must be created separately."

  validation {
    condition = (
      (
        var.domain_name == null ||
        (
          !can(regex("://", var.domain_name)) &&
          !can(regex("/", var.domain_name)) &&
          !can(regex("\\s", var.domain_name)) &&
          !can(regex("\\*", var.domain_name)) &&
          can(regex("^([A-Za-z0-9-]+\\.)+[A-Za-z0-9-]+$", var.domain_name))
        )
      )
    )
    error_message = "domain_name must be a hostname only (e.g. example.com), without scheme/path/whitespace/wildcards."
  }
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN that covers drive.<domain_name> (CloudFront) and authdrive.<domain_name> (Cognito custom domain)."

  validation {
    condition = (
      (
        (var.domain_name == null && var.acm_certificate_arn == null) ||
        (var.domain_name != null && var.acm_certificate_arn != null)
      ) &&
      (
        var.acm_certificate_arn == null ||
        can(regex("^arn:aws(-[a-z]+)?:acm:[a-z0-9-]+:[0-9]{12}:certificate\\/.+$", var.acm_certificate_arn))
      )
    )
    error_message = "To use a custom domain, set both domain_name and acm_certificate_arn. If set, acm_certificate_arn must look like a valid ACM certificate ARN."
  }
}
