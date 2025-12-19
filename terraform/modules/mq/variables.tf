#===============================================================================
# Amazon MQ Module Variables
#===============================================================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Amazon MQ will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Amazon MQ deployment (2 subnets required for CLUSTER_MULTI_AZ)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Amazon MQ"
  type        = list(string)
}

variable "instance_type" {
  description = "Amazon MQ instance type"
  type        = string
  default     = "mq.t3.micro"

  validation {
    condition     = can(regex("^mq\\.(t3|m5)\\.(micro|small|medium|large)", var.instance_type))
    error_message = "Instance type must be a valid Amazon MQ instance type (e.g., mq.t3.micro, mq.m5.large)."
  }
}

variable "deployment_mode" {
  description = "Deployment mode: SINGLE_INSTANCE or CLUSTER_MULTI_AZ"
  type        = string
  default     = "CLUSTER_MULTI_AZ"

  validation {
    condition     = contains(["SINGLE_INSTANCE", "CLUSTER_MULTI_AZ"], var.deployment_mode)
    error_message = "Deployment mode must be either SINGLE_INSTANCE or CLUSTER_MULTI_AZ."
  }
}

variable "engine_version" {
  description = "RabbitMQ engine version"
  type        = string
  default     = "3.11.20"
}

variable "mq_username" {
  description = "Admin username for Amazon MQ"
  type        = string
  default     = "admin"

  validation {
    condition     = length(var.mq_username) >= 2 && length(var.mq_username) <= 100
    error_message = "Username must be between 2 and 100 characters."
  }
}

variable "enable_audit_logs" {
  description = "Enable audit logging for Amazon MQ"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms (empty string to disable)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
