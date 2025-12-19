# Production Environment Configuration

# General
aws_region   = "us-east-1"
project_name = "cloud-design"
environment  = "production"

# VPC Configuration
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

# EKS Configuration
eks_cluster_version = "1.28"

eks_node_groups = {
  general = {
    desired_size   = 3
    min_size       = 2
    max_size       = 10
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
  }
}

# RDS Configuration
rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_max_allocated_storage   = 100
rds_multi_az                = true
rds_backup_retention_period = 7

# Amazon MQ Configuration
mq_instance_type   = "mq.t3.micro"
mq_deployment_mode = "CLUSTER_MULTI_AZ"

# ALB Configuration
# Replace with your ACM certificate ARN
acm_certificate_arn = ""  # Leave empty to create ALB with HTTP only

# Cognito Configuration
cognito_callback_urls = ["https://api.cloud-design.com/callback"]
cognito_logout_urls   = ["https://api.cloud-design.com/logout"]
cognito_enable_mfa    = false

# Monitoring Configuration
alert_email               = "devops@example.com"
cloudwatch_log_retention_days = 30

# Additional Tags
tags = {
  CostCenter = "Engineering"
  Compliance = "GDPR"
  Backup     = "Daily"
}
