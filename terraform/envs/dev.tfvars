project_name           = "rentdirect"
environment            = "dev"
region                 = "eu-west-1"
acm_region             = "us-east-1"
account_id             = "016963913218"
root_account_id        = "573025756531"
assume_role            = "Admin"
root_domain_name       = "rentdirect.homes"
domain_name            = "development.rentdirect.homes"
api_domain_name        = "api.development.rentdirect.homes"
manage_root_email_dns  = true
vpc_cidr               = "10.90.0.0/16"
container_architecture = "ARM64"

enable_container_insights       = false
enable_deletion_protection      = false
enable_waf                      = false
enable_rds_proxy                = false
enable_rds_performance_insights = false
enable_monitoring_alarms        = false
enable_alb_https_redirect       = true
alb_health_check_interval       = 15
log_retention_in_days           = 1
monitoring_alarm_email          = "noreply@rentdirect.homes"

django_allowed_hosts = [
  "api.development.rentdirect.homes,development.rentdirect.homes",
]

api = {
  cpu           = 256
  memory        = 512
  port          = 8000
  desired_count = 1
  min_count     = 1
  max_count     = 2
  cpu_target    = 80
}

# Used for payput worker and migration ecs tasks
worker = {
  cpu           = 256
  memory        = 512
  desired_count = 1
}

database = {
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 50
  backup_retention_period = 1
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
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
  Environment = "development"
}
