#===============================================================================
# CloudWatch Monitoring Module
# Purpose: Centralized monitoring, dashboards, and alerting
#===============================================================================

#-------------------------------------------------------------------------------
# SNS Topic for Alerts
#-------------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-${var.environment}-alerts"
  display_name      = "CloudWatch Alerts for ${var.project_name}"
  kms_master_key_id = aws_kms_key.sns.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alerts-topic"
    }
  )
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# KMS Key for SNS encryption
resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-sns-kms"
    }
  )
}

resource "aws_kms_alias" "sns" {
  name          = "alias/${var.project_name}-${var.environment}-sns"
  target_key_id = aws_kms_key.sns.key_id
}

#-------------------------------------------------------------------------------
# CloudWatch Dashboard
#-------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = concat(
      local.eks_widgets,
      local.rds_widgets,
      local.alb_widgets,
      local.mq_widgets
    )
  })
}

locals {
  # EKS Widgets
  eks_widgets = var.eks_cluster_name != "" ? [
    {
      type = "metric"
      properties = {
        metrics = [
          ["AWS/EKS", "cluster_failed_node_count", { stat = "Average", label = "Failed Nodes" }]
        ]
        period = 300
        stat   = "Average"
        region = data.aws_region.current.name
        title  = "EKS Cluster Health"
        yAxis = {
          left = { min = 0 }
        }
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          ["ContainerInsights", "node_cpu_utilization", { stat = "Average" }],
          [".", "node_memory_utilization", { stat = "Average" }]
        ]
        period = 300
        stat   = "Average"
        region = data.aws_region.current.name
        title  = "EKS Node Resource Utilization"
        yAxis = {
          left = { min = 0, max = 100 }
        }
      }
    }
  ] : []

  # RDS Widgets
  rds_widgets = length(var.rds_instance_ids) > 0 ? [
    {
      type = "metric"
      properties = {
        metrics = [
          for instance_id in var.rds_instance_ids : [
            "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", instance_id
          ]
        ]
        period = 300
        stat   = "Average"
        region = data.aws_region.current.name
        title  = "RDS CPU Utilization"
        yAxis = {
          left = { min = 0, max = 100 }
        }
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          for instance_id in var.rds_instance_ids : [
            "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", instance_id
          ]
        ]
        period = 300
        stat   = "Average"
        region = data.aws_region.current.name
        title  = "RDS Database Connections"
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          for instance_id in var.rds_instance_ids : [
            "AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", instance_id
          ]
        ]
        period = 300
        stat   = "Average"
        region = data.aws_region.current.name
        title  = "RDS Free Storage Space"
      }
    }
  ] : []

  # ALB Widgets
  alb_widgets = var.alb_arn_suffix != "" ? [
    {
      type = "metric"
      properties = {
        metrics = [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
          [".", "TargetResponseTime", ".", ".", { stat = "Average", yAxis = "right" }]
        ]
        period = 300
        stat   = "Average"
        region = data.aws_region.current.name
        title  = "ALB Requests and Response Time"
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
          [".", "HTTPCode_Target_4XX_Count", ".", ".", { stat = "Sum" }],
          [".", "HTTPCode_Target_5XX_Count", ".", ".", { stat = "Sum" }]
        ]
        period = 300
        stat   = "Sum"
        region = data.aws_region.current.name
        title  = "ALB HTTP Response Codes"
      }
    }
  ] : []

  # Amazon MQ Widgets
  mq_widgets = var.mq_broker_id != "" ? [
    {
      type = "metric"
      properties = {
        metrics = [
          ["AWS/AmazonMQ", "CpuUtilization", "Broker", var.mq_broker_id],
          [".", "RabbitMQMemUsed", ".", ".", { yAxis = "right" }]
        ]
        period = 300
        stat   = "Average"
        region = data.aws_region.current.name
        title  = "Amazon MQ Resource Utilization"
      }
    },
    {
      type = "metric"
      properties = {
        metrics = [
          ["AWS/AmazonMQ", "MessageCount", "Broker", var.mq_broker_id],
          [".", "MessageReadyCount", ".", "."],
          [".", "MessageUnacknowledgedCount", ".", "."]
        ]
        period = 300
        stat   = "Average"
        region = data.aws_region.current.name
        title  = "Amazon MQ Messages"
      }
    }
  ] : []
}

#-------------------------------------------------------------------------------
# CloudWatch Log Groups
#-------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.project_name}/${var.environment}/application"
  retention_in_days = var.log_retention_days

  kms_key_id = aws_kms_key.logs.arn

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app-logs"
    }
  )
}

# KMS Key for CloudWatch Logs encryption
resource "aws_kms_key" "logs" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-logs-kms"
    }
  )
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project_name}-${var.environment}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

#-------------------------------------------------------------------------------
# Composite Alarms
#-------------------------------------------------------------------------------

resource "aws_cloudwatch_composite_alarm" "critical_infrastructure" {
  alarm_name          = "${var.project_name}-${var.environment}-critical-infrastructure"
  alarm_description   = "Critical infrastructure health composite alarm"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  alarm_rule = join(" OR ", compact([
    var.eks_cluster_name != "" ? "ALARM(${var.project_name}-${var.environment}-eks-node-failures)" : "",
    length(var.rds_instance_ids) > 0 ? "ALARM(${var.project_name}-${var.environment}-rds-critical)" : "",
    var.mq_broker_id != "" ? "ALARM(${var.project_name}-${var.environment}-mq-critical)" : ""
  ]))

  depends_on = [
    aws_cloudwatch_metric_alarm.eks_node_failures,
    aws_cloudwatch_metric_alarm.rds_cpu_high,
    aws_cloudwatch_metric_alarm.mq_cpu_high
  ]

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Individual CloudWatch Alarms
#-------------------------------------------------------------------------------

# EKS Alarms
resource "aws_cloudwatch_metric_alarm" "eks_node_failures" {
  count               = var.eks_cluster_name != "" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-eks-node-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_failed_node_count"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "EKS cluster has failed nodes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  tags = var.tags
}

# RDS Alarms
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count               = length(var.rds_instance_ids) > 0 ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-rds-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "RDS CPU utilization is critically high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_ids[0]
  }

  tags = var.tags
}

# Amazon MQ Alarms
resource "aws_cloudwatch_metric_alarm" "mq_cpu_high" {
  count               = var.mq_broker_id != "" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-mq-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CpuUtilization"
  namespace           = "AWS/AmazonMQ"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Amazon MQ CPU utilization is too high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    Broker = var.mq_broker_id
  }

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Data Sources
#-------------------------------------------------------------------------------

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
