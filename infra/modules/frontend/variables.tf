variable "frontend_dir" {
  type = string
}

variable "frontend_bucket_id" {
  type = string
}

variable "cloud_drive_bucket_id" {
  type = string
}

variable "cloud_drive_bucket_name" {
  type = string
}

variable "frontend_origin" {
  type = string
}

variable "frontend_redirect_uri" {
  type = string
}

variable "cognito_client_id" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_user_pool_domain" {
  type = string
}

variable "cognito_login_url" {
  type    = string
  default = null
}

variable "cognito_identity_pool_id" {
  type = string
}

variable "region" {
  type = string
}

variable "upload_url" {
  type = string
}
