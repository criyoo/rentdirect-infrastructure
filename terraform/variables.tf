variable "project_name" {
  description = "Short project identifier used in names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "region" {
  description = "Primary AWS region."
  type        = string
}

variable "acm_region" {
  description = "ACM region for edge certificates if later needed."
  type        = string
}

variable "account_id" {
  description = "Workload AWS account ID."
  type        = string
}

variable "assume_role" {
  description = "Role to assume inside the workload account."
  type        = string
}

variable "root_account_id" {
  description = "Management/root AWS account ID."
  type        = string
}

variable "root_admin_role_name" {
  description = "Optional role name to assume inside the root account."
  type        = string
  default     = null
  nullable    = true
}

variable "root_domain_name" {
  description = "Hosted zone root domain."
  type        = string
}

variable "domain_name" {
  description = "Public web hostname."
  type        = string
}

variable "api_domain_name" {
  description = "Optional dedicated public API hostname. Leave empty to serve the API on the main domain under /api."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "container_architecture" {
  description = "Fargate CPU architecture."
  type        = string
  default     = "ARM64"
}

variable "django_allowed_hosts" {
  description = "Additional Django allowed hosts."
  type        = list(string)
  default     = []
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights."
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on selected resources."
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 14
}

variable "api" {
  description = "Backend ECS sizing and autoscaling."
  type = object({
    cpu           = number
    memory        = number
    port          = number
    desired_count = number
    min_count     = number
    max_count     = number
    cpu_target    = number
  })
}

variable "worker" {
  description = "Backend ECS service for the payout worker."
  type = object({
    cpu           = number
    memory        = number
    desired_count = number
  })
}

variable "database" {
  description = "RDS PostgreSQL settings."
  type = object({
    instance_class          = string
    allocated_storage       = number
    max_allocated_storage   = number
    backup_retention_period = number
    multi_az                = bool
    deletion_protection     = bool
    skip_final_snapshot     = bool
    engine_version          = string
    name                    = string
    username                = string
  })
}

variable "cache" {
  description = "ElastiCache Redis settings."
  type = object({
    enabled                    = bool
    node_type                  = string
    engine_version             = string
    replica_count              = number
    multi_az_enabled           = bool
    transit_encryption_enabled = optional(bool, false)
  })
}

variable "enable_waf" {
  description = "Enable AWS WAF on the ALB and frontend CloudFront distribution."
  type        = bool
  default     = false
}

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy for the API database connections."
  type        = bool
  default     = false
}

variable "enable_rds_performance_insights" {
  description = "Enable RDS Performance Insights."
  type        = bool
  default     = false
}

variable "enable_monitoring_alarms" {
  description = "Enable CloudWatch alarms and SNS notifications."
  type        = bool
  default     = false
}

variable "monitoring_alarm_email" {
  description = "Email address for production CloudWatch alarm notifications."
  type        = string
  default     = ""
}

variable "enable_alb_https_redirect" {
  description = "Redirect ALB HTTP traffic to HTTPS."
  type        = bool
  default     = false
}

variable "alb_health_check_interval" {
  description = "ALB target group health check interval in seconds."
  type        = number
  default     = 30
}

# variable "app_string_parameters" {
#   description = "Non-sensitive application settings written to SSM."
#   type        = map(string)
#   default     = {}
# }

variable "api_secure_environment" {
  description = "Sensitive application settings written to SSM SecureString."
  type        = map(string)
  sensitive   = true
  default     = {}

  validation {
    condition     = trimspace(lookup(var.api_secure_environment, "POSTGRES_PASSWORD", "")) != ""
    error_message = "api_secure_environment must include a non-empty POSTGRES_PASSWORD."
  }

  validation {
    condition     = trimspace(lookup(var.api_secure_environment, "DJANGO_SECRET_KEY", "")) != ""
    error_message = "api_secure_environment must include DJANGO_SECRET_KEY."
  }
}

variable "tags" {
  description = "Additional shared tags."
  type        = map(string)
  default     = {}
}


variable "manage_root_email_dns" {
  description = "Whether this workspace should manage the shared Route 53 records for Hostinger Email."
  type        = bool
}

variable "godaddy_email_dns" {
  description = "Hostinger Email DNS records for the root domain."
  type = object({
    mx_ttl       = number
    spf_ttl      = number
    dmarc_ttl    = number
    dkim_ttl     = number
    srv_ttl      = number
    mx_records   = list(object({ priority = number, value = string }))
    spf_record   = list(string)
    dmarc_record = string
    srv_record   = map(string)
    dkim_records = map(string)
  })

  default = {
    mx_ttl    = 14400
    spf_ttl   = 3600
    dmarc_ttl = 3600
    dkim_ttl  = 300
    srv_ttl   = 3600
    mx_records = [
      { priority = 0, value = "smtp.secureserver.net" },
      { priority = 10, value = "mailstore1.secureserver.net" },
    ]
    spf_record = [
      "v=spf1 include:secureserver.net -all",
      "T1242627"
    ]
    dmarc_record = "v=DMARC1; p=reject; rua=mailto:dmarc_rua@onsecureserver.net; adkim=r; aspf=r;"
    srv_record = {
      "_autodiscover._tcp" = "100 1 443 autodiscover.secureserver.net"
    }
    dkim_records = {
      "email"                    = "email.secureserver.net"
      "secureserver1._domainkey" = "s1.dkim.rentdirect_homes.749.onsecureserver.net."
      "secureserver2._domainkey" = "s2.dkim.rentdirect_homes.749.onsecureserver.net."
    }
  }
}
