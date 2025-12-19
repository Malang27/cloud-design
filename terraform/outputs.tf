# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

output "eks_configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# RDS Outputs
output "rds_inventory_endpoint" {
  description = "RDS Inventory endpoint"
  value       = module.rds_inventory.db_instance_endpoint
  sensitive   = true
}

output "rds_billing_endpoint" {
  description = "RDS Billing endpoint"
  value       = module.rds_billing.db_instance_endpoint
  sensitive   = true
}

output "rds_inventory_database_name" {
  description = "RDS Inventory database name"
  value       = module.rds_inventory.database_name
}

output "rds_billing_database_name" {
  description = "RDS Billing database name"
  value       = module.rds_billing.database_name
}

# Amazon MQ Outputs
output "rabbitmq_broker_id" {
  description = "Amazon MQ broker ID"
  value       = module.rabbitmq.broker_id
}

output "rabbitmq_endpoints" {
  description = "RabbitMQ endpoints (AMQP and Console)"
  value       = module.rabbitmq.broker_endpoints
  sensitive   = true
}

output "rabbitmq_credentials_secret_arn" {
  description = "ARN of Secrets Manager secret containing RabbitMQ credentials"
  value       = module.rabbitmq.credentials_secret_arn
  sensitive   = true
}

# ALB Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

# Cognito Outputs
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = module.cognito.user_pool_arn
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.app_client_id
  sensitive   = true
}

# Monitoring Outputs
output "sns_topic_arn" {
  description = "SNS Topic ARN for alerts"
  value       = module.monitoring.sns_topic_arn
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-${var.environment}"
}

# Useful Commands
output "useful_commands" {
  description = "Useful commands for this deployment"
  value = <<-EOT
    # Configure kubectl
    ${module.eks.configure_kubectl_command}

    # Get all pods
    kubectl get pods --all-namespaces

    # Get services
    kubectl get svc --all-namespaces

    # Get ingress
    kubectl get ingress

    # View ALB
    echo "ALB URL: http://${module.alb.alb_dns_name}"

    # View RabbitMQ Console
    echo "RabbitMQ Console: ${module.rabbitmq.broker_endpoints.console}"

    # View CloudWatch Dashboard
    echo "CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-${var.environment}"
  EOT
}
