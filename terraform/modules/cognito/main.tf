#===============================================================================
# AWS Cognito User Pool Module
# Purpose: User authentication and authorization
#===============================================================================

#-------------------------------------------------------------------------------
# Cognito User Pool
#-------------------------------------------------------------------------------

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.environment}-users"

  # Username configuration
  username_attributes = var.username_attributes
  username_configuration {
    case_sensitive = false
  }

  # Auto-verified attributes
  auto_verified_attributes = var.auto_verified_attributes

  # Password policy
  password_policy {
    minimum_length                   = var.password_minimum_length
    require_lowercase                = var.password_require_lowercase
    require_uppercase                = var.password_require_uppercase
    require_numbers                  = var.password_require_numbers
    require_symbols                  = var.password_require_symbols
    temporary_password_validity_days = 7
  }

  # MFA configuration
  mfa_configuration = var.mfa_configuration

  # Software token MFA
  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration != "OFF" ? [1] : []
    content {
      enabled = true
    }
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    dynamic "recovery_mechanism" {
      for_each = contains(var.username_attributes, "phone_number") ? [1] : []
      content {
        name     = "verified_phone_number"
        priority = 2
      }
    }
  }

  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Advanced security
  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  # Device tracking
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  # User invitation
  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only

    invite_message_template {
      email_subject = "Welcome to ${var.project_name}"
      email_message = "Hello {username}, your temporary password is {####}"
      sms_message   = "Your temporary password is {####}"
    }
  }

  # Deletion protection
  deletion_protection = var.enable_deletion_protection ? "ACTIVE" : "INACTIVE"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-user-pool"
    }
  )
}

#-------------------------------------------------------------------------------
# User Pool Domain
#-------------------------------------------------------------------------------

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.environment}-${random_string.domain_suffix.result}"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "random_string" "domain_suffix" {
  length  = 8
  special = false
  upper   = false
}

#-------------------------------------------------------------------------------
# App Client
#-------------------------------------------------------------------------------

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-${var.environment}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = var.oauth_flows
  allowed_oauth_scopes                 = var.oauth_scopes

  # Callback URLs
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Token validity
  access_token_validity  = var.access_token_validity
  id_token_validity      = var.id_token_validity
  refresh_token_validity = var.refresh_token_validity

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Supported identity providers
  supported_identity_providers = var.identity_providers

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Read/write attributes
  read_attributes = [
    "email",
    "email_verified",
    "name",
    "updated_at"
  ]

  write_attributes = [
    "email",
    "name",
    "updated_at"
  ]
}

#-------------------------------------------------------------------------------
# User Pool Groups
#-------------------------------------------------------------------------------

resource "aws_cognito_user_pool_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrator group with full access"
  precedence   = 1
}

resource "aws_cognito_user_pool_group" "users" {
  name         = "users"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Regular users group"
  precedence   = 10
}

#-------------------------------------------------------------------------------
# CloudWatch Log Group for Lambda Triggers
#-------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cognito_triggers" {
  name              = "/aws/cognito/${aws_cognito_user_pool.main.name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-cognito-triggers"
    }
  )
}

#-------------------------------------------------------------------------------
# CloudWatch Alarms
#-------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "user_authentication_failures" {
  alarm_name          = "${var.project_name}-${var.environment}-cognito-auth-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserAuthenticationFailures"
  namespace           = "AWS/Cognito"
  period              = 300
  statistic           = "Sum"
  threshold           = 50
  alarm_description   = "High number of Cognito authentication failures"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    UserPool = aws_cognito_user_pool.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "account_takeover_risk" {
  alarm_name          = "${var.project_name}-${var.environment}-cognito-account-takeover"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AccountTakeOverRisk"
  namespace           = "AWS/Cognito"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Potential account takeover attempts detected"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    UserPool = aws_cognito_user_pool.main.id
  }

  tags = var.tags
}
