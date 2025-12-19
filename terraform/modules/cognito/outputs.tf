#===============================================================================
# Cognito User Pool Module Outputs
#===============================================================================

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Cognito User Pool domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "user_pool_domain_cloudfront_distribution" {
  description = "CloudFront distribution for User Pool domain"
  value       = aws_cognito_user_pool_domain.main.cloudfront_distribution_arn
}

output "app_client_id" {
  description = "App client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "app_client_secret" {
  description = "App client secret (sensitive)"
  value       = aws_cognito_user_pool_client.main.client_secret
  sensitive   = true
}

output "admin_group_name" {
  description = "Admin group name"
  value       = aws_cognito_user_pool_group.admin.name
}

output "users_group_name" {
  description = "Users group name"
  value       = aws_cognito_user_pool_group.users.name
}

output "hosted_ui_url" {
  description = "Cognito Hosted UI URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

#-------------------------------------------------------------------------------
# Data Sources
#-------------------------------------------------------------------------------

data "aws_region" "current" {}
