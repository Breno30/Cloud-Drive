module "storage" {
  source = "./modules/storage"
}

module "cdn" {
  source = "./modules/cdn"

  frontend_bucket_regional_domain_name = module.storage.frontend_bucket_regional_domain_name
  frontend_bucket_arn                  = module.storage.frontend_bucket_arn
  frontend_bucket_id                   = module.storage.frontend_bucket_id
  name_suffix                          = random_id.name_suffix.hex
}

module "cognito" {
  source = "./modules/cognito"

  frontend_redirect_uri  = local.frontend_redirect_uri
  frontend_origin        = local.frontend_origin
  cloud_drive_bucket_arn = module.storage.cloud_drive_bucket_arn
  name_suffix            = random_id.name_suffix.hex

  ui_css_file  = "${path.module}/../frontend/assets/cognito/ui.css"
  ui_logo_file = "${path.module}/../frontend/assets/cognito/logo.png"
}

module "frontend" {
  source = "./modules/frontend"

  frontend_dir            = "${path.module}/../frontend"
  frontend_bucket_id      = module.storage.frontend_bucket_id
  cloud_drive_bucket_id   = module.storage.cloud_drive_bucket_id
  cloud_drive_bucket_name = module.storage.cloud_drive_bucket_name

  frontend_origin       = local.frontend_origin
  frontend_redirect_uri = local.frontend_redirect_uri

  cognito_client_id        = module.cognito.client_id
  cognito_user_pool_id     = module.cognito.user_pool_id
  cognito_user_pool_domain = module.cognito.user_pool_domain
  cognito_login_url        = var.cognito_login_url
  cognito_identity_pool_id = module.cognito.identity_pool_id
  region                   = data.aws_region.current.name
  upload_url               = module.uploader.upload_url
}

module "uploader" {
  source = "./modules/uploader"

  cloud_drive_bucket_name = module.storage.cloud_drive_bucket_name
  cloud_drive_bucket_arn  = module.storage.cloud_drive_bucket_arn
  user_pool_id            = module.cognito.user_pool_id
  identity_pool_id        = module.cognito.identity_pool_id
  region                  = data.aws_region.current.name
  frontend_origin         = local.frontend_origin
  quota_bytes             = 10 * 1024 * 1024
  name_suffix             = random_id.name_suffix.hex
}
