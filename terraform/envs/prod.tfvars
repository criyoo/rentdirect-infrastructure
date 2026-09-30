project_name          = "rentdirect"
environment           = "prod"
region                = "eu-west-1"
acm_region            = "us-east-1"
account_id            = "126000554558"
root_account_id       = "573025756531"
assume_role           = "Admin"
root_domain_name      = "rentdirect.homes"
domain_name           = "rentdirect.homes"
api_domain_name       = "api.rentdirect.homes"
manage_root_email_dns = false

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
  "api.rentdirect.homes,rentdirect.homes",
]

api = {
  cpu           = 1024
  memory        = 2048
  port          = 8000
  desired_count = 1
  min_count     = 1
  max_count     = 4
  cpu_target    = 70
}

# Used for payout worker and migration ECS tasks
worker = {
  cpu           = 256
  memory        = 512
  desired_count = 1
}

payment_queue = {
  visibility_timeout_seconds                 = 300
  message_retention_seconds                  = 1209600
  max_receive_count                          = 5
  receive_wait_time_seconds                  = 20
  ready_payout_schedule_expression           = "rate(15 minutes)"
  subscription_renewal_schedule_expression   = "rate(1 hour)"
  pending_reconciliation_schedule_expression = "rate(5 minutes)"
}

database = {
  instance_class          = "db.t4g.small"
  allocated_storage       = 20
  max_allocated_storage   = 1000
  backup_retention_period = 7
  multi_az                = false
  deletion_protection     = true
  skip_final_snapshot     = false
  engine_version          = "18.3"
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

tags = {
  Project     = "rentdirect"
  Owner       = "platform"
  Environment = "production"
  ManageBy    = "terraform"
}
