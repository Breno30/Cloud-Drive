variable "domain_name" {
  type        = string
  description = "Base domain name (host only, no scheme). Terraform derives drive.<domain_name> and authdrive.<domain_name> automatically. DNS records must be created separately."

  validation {
    condition = (
      (
        !can(regex("://", var.domain_name)) &&
        !can(regex("/", var.domain_name)) &&
        !can(regex("\\s", var.domain_name)) &&
        !can(regex("\\*", var.domain_name)) &&
        can(regex("^([A-Za-z0-9-]+\\.)+[A-Za-z0-9-]+$", var.domain_name))
      )
    )
    error_message = "domain_name must be a hostname only (e.g. example.com), without scheme/path/whitespace/wildcards."
  }
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN that covers drive.<domain_name> (CloudFront) and authdrive.<domain_name> (Cognito custom domain)."
}
