#===============================================================================
# Amazon MQ Module Outputs
#===============================================================================

output "broker_id" {
  description = "Amazon MQ broker ID"
  value       = aws_mq_broker.main.id
}

output "broker_arn" {
  description = "Amazon MQ broker ARN"
  value       = aws_mq_broker.main.arn
}

output "broker_endpoints" {
  description = "Amazon MQ broker endpoints"
  value = {
    amqp    = aws_mq_broker.main.instances[0].endpoints[0]
    console = aws_mq_broker.main.instances[0].console_url
  }
}

output "security_group_id" {
  description = "Security group ID for Amazon MQ"
  value       = aws_security_group.mq.id
}

output "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing MQ credentials"
  value       = aws_secretsmanager_secret.mq_credentials.arn
}

output "credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing MQ credentials"
  value       = aws_secretsmanager_secret.mq_credentials.name
}

output "kms_key_id" {
  description = "KMS key ID used for Amazon MQ encryption"
  value       = aws_kms_key.mq.id
}

output "kms_key_arn" {
  description = "KMS key ARN used for Amazon MQ encryption"
  value       = aws_kms_key.mq.arn
}

output "configuration_id" {
  description = "Amazon MQ configuration ID"
  value       = aws_mq_configuration.main.id
}

output "configuration_revision" {
  description = "Amazon MQ configuration latest revision"
  value       = aws_mq_configuration.main.latest_revision
}
