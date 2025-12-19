terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket         = "cloud-design-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cloud-design"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps Team"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr              = var.vpc_cidr
  availability_zones    = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  project_name = var.project_name
  environment  = var.environment
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.eks_cluster_version

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  node_groups = var.eks_node_groups

  enable_cluster_autoscaler = true
  enable_metrics_server     = true
  enable_aws_lb_controller  = true

  project_name = var.project_name
  environment  = var.environment
}

# RDS Inventory Database
module "rds_inventory" {
  source = "./modules/rds"

  identifier            = "${var.project_name}-inventory-${var.environment}"
  engine                = "postgres"
  engine_version        = "15.4"
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  multi_az              = var.rds_multi_az
  storage_encrypted     = true

  database_name = "inventory"
  database_user = "inventory_user"

  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.database_subnet_ids
  allowed_security_groups = [module.eks.node_security_group_id]

  backup_retention_period = var.rds_backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  enable_enhanced_monitoring = true
  monitoring_interval        = 60

  project_name = var.project_name
  environment  = var.environment
}

# RDS Billing Database
module "rds_billing" {
  source = "./modules/rds"

  identifier            = "${var.project_name}-billing-${var.environment}"
  engine                = "postgres"
  engine_version        = "15.4"
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  multi_az              = var.rds_multi_az
  storage_encrypted     = true

  database_name = "orders"
  database_user = "billing_user"

  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.database_subnet_ids
  allowed_security_groups = [module.eks.node_security_group_id]

  backup_retention_period = var.rds_backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  enable_enhanced_monitoring = true
  monitoring_interval        = 60

  project_name = var.project_name
  environment  = var.environment
}

# Amazon MQ (RabbitMQ)
module "rabbitmq" {
  source = "./modules/mq"

  instance_type   = var.mq_instance_type
  deployment_mode = var.mq_deployment_mode
  engine_version  = "3.11.20"

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = module.vpc.private_subnet_cidrs

  mq_username       = "admin"
  enable_audit_logs = var.environment == "production" ? true : false

  log_retention_days = var.cloudwatch_log_retention_days

  project_name = var.project_name
  environment  = var.environment
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  certificate_arn            = var.acm_certificate_arn
  enable_deletion_protection = var.environment == "production" ? true : false
  enable_access_logs         = true
  logs_retention_days        = var.cloudwatch_log_retention_days

  project_name = var.project_name
  environment  = var.environment
}

# Cognito User Pool
module "cognito" {
  source = "./modules/cognito"

  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls

  mfa_configuration          = var.cognito_enable_mfa ? "OPTIONAL" : "OFF"
  enable_deletion_protection = var.environment == "production" ? true : false

  password_minimum_length    = 12
  password_require_lowercase = true
  password_require_uppercase = true
  password_require_numbers   = true
  password_require_symbols   = true

  log_retention_days = var.cloudwatch_log_retention_days

  project_name = var.project_name
  environment  = var.environment
}

# Monitoring & Alarms
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment

  # EKS Monitoring
  eks_cluster_name = module.eks.cluster_name

  # RDS Monitoring
  rds_instance_ids = [
    module.rds_inventory.db_instance_id,
    module.rds_billing.db_instance_id
  ]

  # ALB Monitoring
  alb_arn_suffix = module.alb.alb_arn_suffix

  # Amazon MQ Monitoring
  mq_broker_id = module.rabbitmq.broker_id

  # SNS Topic for alerts
  alert_email = var.alert_email

  # CloudWatch Log Retention
  log_retention_days = var.cloudwatch_log_retention_days
}
