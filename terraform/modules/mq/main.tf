#===============================================================================
# Amazon MQ (RabbitMQ) Module
# Purpose: Managed RabbitMQ message broker with Multi-AZ deployment
#===============================================================================

#-------------------------------------------------------------------------------
# Security Group
#-------------------------------------------------------------------------------

resource "aws_security_group" "mq" {
  name_description = "${var.project_name}-${var.environment}-mq-sg"
  description      = "Security group for Amazon MQ RabbitMQ broker"
  vpc_id           = var.vpc_id

  # RabbitMQ AMQP
  ingress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "RabbitMQ AMQP SSL"
  }

  # RabbitMQ Management Console
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "RabbitMQ Management Console HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mq-sg"
    }
  )
}

#-------------------------------------------------------------------------------
# RabbitMQ User Credentials
#-------------------------------------------------------------------------------

resource "random_password" "mq_password" {
  length  = 32
  special = false # Amazon MQ has restrictions on special characters
}

resource "aws_secretsmanager_secret" "mq_credentials" {
  name                    = "${var.project_name}/${var.environment}/mq/credentials"
  recovery_window_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mq-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "mq_credentials" {
  secret_id = aws_secretsmanager_secret.mq_credentials.id
  secret_string = jsonencode({
    username = var.mq_username
    password = random_password.mq_password.result
    endpoints = {
      amqp    = "amqps://${aws_mq_broker.main.id}.mq.${data.aws_region.current.name}.amazonaws.com:5671"
      console = "https://${aws_mq_broker.main.id}.mq.${data.aws_region.current.name}.amazonaws.com"
    }
  })
}

#-------------------------------------------------------------------------------
# Amazon MQ Broker Configuration
#-------------------------------------------------------------------------------

resource "aws_mq_configuration" "main" {
  name           = "${var.project_name}-${var.environment}-mq-config"
  description    = "RabbitMQ configuration for ${var.project_name}"
  engine_type    = "RabbitMQ"
  engine_version = var.engine_version

  data = <<DATA
# Default RabbitMQ delivery acknowledgement timeout is 30 minutes in milliseconds
consumer_timeout = 1800000

# Increase message TTL to 7 days (in milliseconds)
message_ttl = 604800000

# Enable lazy queues for better memory management
queue_master_locator = min-masters
DATA

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Amazon MQ Broker (RabbitMQ)
#-------------------------------------------------------------------------------

resource "aws_mq_broker" "main" {
  broker_name             = "${var.project_name}-${var.environment}-mq"
  engine_type             = "RabbitMQ"
  engine_version          = var.engine_version
  host_instance_type      = var.instance_type
  deployment_mode         = var.deployment_mode
  storage_type            = "ebs"

  # Security
  security_groups         = [aws_security_group.mq.id]
  subnet_ids              = var.deployment_mode == "CLUSTER_MULTI_AZ" ? var.subnet_ids : [var.subnet_ids[0]]
  publicly_accessible     = false

  # Encryption
  encryption_options {
    use_aws_owned_key = false
    kms_key_id        = aws_kms_key.mq.arn
  }

  # Configuration
  configuration {
    id       = aws_mq_configuration.main.id
    revision = aws_mq_configuration.main.latest_revision
  }

  # Admin user
  user {
    username       = var.mq_username
    password       = random_password.mq_password.result
    console_access = true
  }

  # Maintenance window (Sunday 03:00-04:00 UTC)
  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "03:00"
    time_zone   = "UTC"
  }

  # Logging
  logs {
    general = true
    audit   = var.enable_audit_logs
  }

  # Auto minor version upgrades
  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mq-broker"
    }
  )
}

#-------------------------------------------------------------------------------
# KMS Key for Amazon MQ Encryption
#-------------------------------------------------------------------------------

resource "aws_kms_key" "mq" {
  description             = "KMS key for Amazon MQ encryption - ${var.project_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mq-kms"
    }
  )
}

resource "aws_kms_alias" "mq" {
  name          = "alias/${var.project_name}-${var.environment}-mq"
  target_key_id = aws_kms_key.mq.key_id
}

#-------------------------------------------------------------------------------
# CloudWatch Log Group
#-------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "mq_general" {
  name              = "/aws/amazonmq/broker/${var.project_name}-${var.environment}-mq/general"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mq-general-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "mq_audit" {
  count             = var.enable_audit_logs ? 1 : 0
  name              = "/aws/amazonmq/broker/${var.project_name}-${var.environment}-mq/audit"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-mq-audit-logs"
    }
  )
}

#-------------------------------------------------------------------------------
# CloudWatch Alarms
#-------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "mq_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-mq-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CpuUtilization"
  namespace           = "AWS/AmazonMQ"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Amazon MQ CPU utilization is too high"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    Broker = aws_mq_broker.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "mq_memory" {
  alarm_name          = "${var.project_name}-${var.environment}-mq-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RabbitMQMemUsed"
  namespace           = "AWS/AmazonMQ"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Amazon MQ memory utilization is too high"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    Broker = aws_mq_broker.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "mq_disk" {
  alarm_name          = "${var.project_name}-${var.environment}-mq-low-disk"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RabbitMQDiskFree"
  namespace           = "AWS/AmazonMQ"
  period              = 300
  statistic           = "Average"
  threshold           = 20 # 20% free space remaining
  alarm_description   = "Amazon MQ disk space is running low"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    Broker = aws_mq_broker.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "mq_connection_count" {
  alarm_name          = "${var.project_name}-${var.environment}-mq-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConnectionCount"
  namespace           = "AWS/AmazonMQ"
  period              = 300
  statistic           = "Average"
  threshold           = 900 # Alert at 90% of 1000 connection limit
  alarm_description   = "Amazon MQ connection count is too high"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    Broker = aws_mq_broker.main.id
  }

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Data Sources
#-------------------------------------------------------------------------------

data "aws_region" "current" {}
