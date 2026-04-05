module "storage" {
  source = "./modules/storage"
}

module "cdn" {
  source = "./modules/cdn"

  frontend_bucket_website_endpoint = module.storage.frontend_bucket_website_endpoint
}

module "cognito" {
  source = "./modules/cognito"

  frontend_redirect_uri = local.frontend_redirect_uri
  cloud_drive_bucket_arn = module.storage.cloud_drive_bucket_arn

  ui_css_file  = "${path.module}/../frontend/assets/cognito/ui.css"
  ui_logo_file = "${path.module}/../frontend/assets/cognito/logo.png"
}

module "frontend" {
  source = "./modules/frontend"

  frontend_dir          = "${path.module}/../frontend"
  frontend_bucket_id    = module.storage.frontend_bucket_id
  cloud_drive_bucket_id = module.storage.cloud_drive_bucket_id
  cloud_drive_bucket_name = module.storage.cloud_drive_bucket_name

  frontend_origin        = local.frontend_origin
  frontend_redirect_uri  = local.frontend_redirect_uri

  cognito_client_id       = module.cognito.client_id
  cognito_user_pool_id    = module.cognito.user_pool_id
  cognito_user_pool_domain = module.cognito.user_pool_domain
  cognito_identity_pool_id = module.cognito.identity_pool_id
  region                  = data.aws_region.current.name
}
