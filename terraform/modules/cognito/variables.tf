#===============================================================================
# Cognito User Pool Module Variables
#===============================================================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "username_attributes" {
  description = "Attributes that can be used as usernames"
  type        = list(string)
  default     = ["email"]

  validation {
    condition = alltrue([
      for attr in var.username_attributes : contains(["email", "phone_number"], attr)
    ])
    error_message = "Username attributes must be either 'email' or 'phone_number'."
  }
}

variable "auto_verified_attributes" {
  description = "Attributes to be auto-verified"
  type        = list(string)
  default     = ["email"]

  validation {
    condition = alltrue([
      for attr in var.auto_verified_attributes : contains(["email", "phone_number"], attr)
    ])
    error_message = "Auto verified attributes must be either 'email' or 'phone_number'."
  }
}

variable "password_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 12

  validation {
    condition     = var.password_minimum_length >= 6 && var.password_minimum_length <= 99
    error_message = "Password minimum length must be between 6 and 99."
  }
}

variable "password_require_lowercase" {
  description = "Require lowercase characters in password"
  type        = bool
  default     = true
}

variable "password_require_uppercase" {
  description = "Require uppercase characters in password"
  type        = bool
  default     = true
}

variable "password_require_numbers" {
  description = "Require numbers in password"
  type        = bool
  default     = true
}

variable "password_require_symbols" {
  description = "Require symbols in password"
  type        = bool
  default     = true
}

variable "mfa_configuration" {
  description = "MFA configuration: OFF, ON, or OPTIONAL"
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "MFA configuration must be OFF, ON, or OPTIONAL."
  }
}

variable "advanced_security_mode" {
  description = "Advanced security mode: OFF, AUDIT, or ENFORCED"
  type        = string
  default     = "AUDIT"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "Advanced security mode must be OFF, AUDIT, or ENFORCED."
  }
}

variable "allow_admin_create_user_only" {
  description = "Only allow administrators to create users"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for User Pool"
  type        = bool
  default     = false
}

variable "callback_urls" {
  description = "List of allowed callback URLs"
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "List of allowed logout URLs"
  type        = list(string)
  default     = ["http://localhost:3000/logout"]
}

variable "oauth_flows" {
  description = "OAuth flows to enable"
  type        = list(string)
  default     = ["code", "implicit"]

  validation {
    condition = alltrue([
      for flow in var.oauth_flows : contains(["code", "implicit", "client_credentials"], flow)
    ])
    error_message = "OAuth flows must be code, implicit, or client_credentials."
  }
}

variable "oauth_scopes" {
  description = "OAuth scopes to allow"
  type        = list(string)
  default     = ["email", "openid", "profile"]
}

variable "identity_providers" {
  description = "List of supported identity providers"
  type        = list(string)
  default     = ["COGNITO"]
}

variable "access_token_validity" {
  description = "Access token validity in hours"
  type        = number
  default     = 1

  validation {
    condition     = var.access_token_validity >= 1 && var.access_token_validity <= 24
    error_message = "Access token validity must be between 1 and 24 hours."
  }
}

variable "id_token_validity" {
  description = "ID token validity in hours"
  type        = number
  default     = 1

  validation {
    condition     = var.id_token_validity >= 1 && var.id_token_validity <= 24
    error_message = "ID token validity must be between 1 and 24 hours."
  }
}

variable "refresh_token_validity" {
  description = "Refresh token validity in days"
  type        = number
  default     = 30

  validation {
    condition     = var.refresh_token_validity >= 1 && var.refresh_token_validity <= 3650
    error_message = "Refresh token validity must be between 1 and 3650 days."
  }
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
