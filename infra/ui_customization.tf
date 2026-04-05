resource "aws_cognito_user_pool_ui_customization" "spa" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  client_id    = aws_cognito_user_pool_client.spa_client.id
  css          = file("${path.module}/../frontend/cognito-ui.css")
  image_file   = filebase64("${path.module}/../frontend/src/images/logo.png")
}
