#===============================================================================
# CloudWatch Monitoring Module Outputs
#===============================================================================

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.alerts.name
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "application_log_group_name" {
  description = "Application log group name"
  value       = aws_cloudwatch_log_group.application.name
}

output "application_log_group_arn" {
  description = "Application log group ARN"
  value       = aws_cloudwatch_log_group.application.arn
}

output "logs_kms_key_id" {
  description = "KMS key ID for CloudWatch Logs encryption"
  value       = aws_kms_key.logs.id
}

output "logs_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Logs encryption"
  value       = aws_kms_key.logs.arn
}

output "sns_kms_key_id" {
  description = "KMS key ID for SNS encryption"
  value       = aws_kms_key.sns.id
}

output "sns_kms_key_arn" {
  description = "KMS key ARN for SNS encryption"
  value       = aws_kms_key.sns.arn
}

#-------------------------------------------------------------------------------
# Data Sources
#-------------------------------------------------------------------------------

data "aws_region" "current" {}
