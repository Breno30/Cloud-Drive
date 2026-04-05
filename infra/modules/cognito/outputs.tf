output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.hosted_ui.domain
}

output "user_pool_endpoint" {
  value = aws_cognito_user_pool.user_pool.endpoint
}

output "client_id" {
  value = aws_cognito_user_pool_client.spa_client.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.identity_pool.id
}
