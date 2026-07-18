terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.root]
    }
  }
}

variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "domain_name" {
  type = string
}

variable "api_domain_name" {
  type    = string
  default = ""
}

variable "hosted_zone_id" {
  type = string
}

variable "cloudfront_certificate_arn" {
  type = string
}

variable "alb_certificate_arn" {
  type = string
}

variable "media_bucket_id" {
  type = string
}

variable "media_bucket_arn" {
  type = string
}

variable "media_bucket_regional_domain_name" {
  type = string
}

variable "frontend_bucket_id" {
  type = string
}

variable "frontend_bucket_arn" {
  type = string
}

variable "frontend_bucket_regional_domain_name" {
  type = string
}

variable "enable_alb_https_redirect" {
  description = "Redirect HTTP listener traffic to HTTPS."
  type        = bool
  default     = false
}

variable "cloudfront_web_acl_arn" {
  description = "Optional CloudFront-scoped WAF Web ACL ARN (must be created in us-east-1)."
  type        = string
  default     = null
  nullable    = true
}

variable "alb_health_check_interval" {
  description = "ALB target group health check interval in seconds."
  type        = number
  default     = 30
}

variable "enable_deletion_protection" {
  type = bool
}

variable "enable_waf" {
  type = bool
}
