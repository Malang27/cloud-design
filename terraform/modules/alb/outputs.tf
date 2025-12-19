#===============================================================================
# Application Load Balancer Module Outputs
#===============================================================================

output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix (for CloudWatch metrics)"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Route53 zone ID"
  value       = aws_lb.main.zone_id
}

output "security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN (empty if HTTPS not enabled)"
  value       = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : ""
}

output "default_target_group_arn" {
  description = "Default target group ARN"
  value       = aws_lb_target_group.default.arn
}

output "default_target_group_arn_suffix" {
  description = "Default target group ARN suffix (for CloudWatch metrics)"
  value       = aws_lb_target_group.default.arn_suffix
}

output "access_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs (empty if logs disabled)"
  value       = var.enable_access_logs ? aws_s3_bucket.alb_logs[0].id : ""
}
