terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

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
