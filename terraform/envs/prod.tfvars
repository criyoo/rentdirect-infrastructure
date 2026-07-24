project_name     = "rentdirect"
environment      = "prod"
region           = "eu-west-1"
acm_region       = "us-east-1"
account_id       = ""
root_account_id  = "656111643297"
assume_role      = "Admin"
root_domain_name = "rentdirect.homes"
domain_name      = "rentdirect.homes"
api_domain_name  = "api.rentdirect.homes"

vpc_cidr               = "10.100.0.0/16"
container_architecture = "ARM64"

enable_container_insights       = false
enable_deletion_protection      = true
enable_waf                      = true
enable_rds_proxy                = true
enable_rds_performance_insights = true
enable_monitoring_alarms        = true
enable_alb_https_redirect       = true
alb_health_check_interval       = 15
log_retention_in_days           = 30
monitoring_alarm_email          = "noreply@rentdirect.homes"

django_allowed_hosts = [
  "api.rentdirect.homes",
]

api = {
  cpu           = 1024
  memory        = 2048
  desired_count = 1
  min_count     = 2
  max_count     = 4
  cpu_target    = 70
}

# Used for payput worker and migration ecs tasks
worker = {
  cpu           = 256
  memory        = 512
  desired_count = 1
}

database = {
  instance_class          = "db.t4g.small"
  allocated_storage       = 20
  max_allocated_storage   = 500
  backup_retention_period = 7
  multi_az                = false
  deletion_protection     = true
  skip_final_snapshot     = false
  engine_version          = "18.1"
  name                    = "rentdirect"
  username                = "rentdirect"
}

cache = {
  enabled                    = true
  node_type                  = "cache.t4g.micro"
  engine_version             = "9.0"
  replica_count              = 0
  multi_az_enabled           = false
  transit_encryption_enabled = true
}

# app_string_parameters = {
#   DEFAULT_FROM_EMAIL = "noreply@rentdirect.homes"
#   EMAIL_BACKEND      = "django.core.mail.backends.smtp.EmailBackend"
#   EMAIL_HOST         = "smtpout.secureserver.net"
#   EMAIL_PORT         = "587"
#   EMAIL_HOST_USER    = "info@rentdirect.homes"
#   EMAIL_USE_TLS      = "true"
#   EMAIL_USE_SSL      = "false"
#   EMAIL_TIMEOUT      = "60"
#   SERVER_EMAIL       = "info@rentdirect.homes"
#   FLUTTERWAVE_V3_API_BASE_URL = "https://api.flutterwave.com/v3"
#   FLUTTERWAVE_API_BASE_URL    = "https://f4bexperience.flutterwave.com"
#   FLUTTERWAVE_TOKEN_URL       = "https://idp.flutterwave.com/realms/flutterwave/protocol/openid-connect/token"
#   SEED_DEMO_ACCOUNTS   = "false"
# }

tags = {
  Project     = "rentdirect"
  Owner       = "platform"
  Environment = "production"
}
