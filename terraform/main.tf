module "security" {
  source = "./modules/security"

  providers = {
    aws      = aws
    aws.acm  = aws.acm
    aws.root = aws.root
  }

  name_prefix             = local.name_prefix
  common_tags             = local.common_tags
  root_domain_name        = var.root_domain_name
  enabled                 = true
  rate_limit              = 2000
  domain_name             = var.domain_name
  api_domain_name         = var.api_domain_name
  hosted_zone_id          = local.route53_zone_id
  cloudfront_distribution = module.networking.cloudfront_distribution
}


module "networking" {
  source = "./modules/networking"

  providers = {
    aws      = aws
    aws.root = aws.root
  }

  name_prefix                          = local.name_prefix
  common_tags                          = local.common_tags
  environment                          = var.environment
  vpc_cidr                             = var.vpc_cidr
  availability_zones                   = local.availability_zones
  domain_name                          = var.domain_name
  api_domain_name                      = var.api_domain_name
  hosted_zone_id                       = local.route53_zone_id
  cloudfront_certificate_arn           = module.security.cloudfront_certificate_arn
  alb_certificate_arn                  = module.security.alb_certificate_arn
  media_bucket_id                      = module.storage.media_bucket_name
  media_bucket_arn                     = module.storage.media_bucket_arn
  media_bucket_regional_domain_name    = module.storage.media_bucket_domain_name
  frontend_bucket_id                   = module.storage.frontend_bucket_id
  frontend_bucket_arn                  = module.storage.frontend_bucket_arn
  frontend_bucket_regional_domain_name = module.storage.frontend_bucket_regional_domain_name
  enable_deletion_protection           = var.enable_deletion_protection
  enable_alb_https_redirect            = var.enable_alb_https_redirect
  alb_health_check_interval            = var.alb_health_check_interval
  cloudfront_web_acl_arn               = var.enable_waf ? module.security.cloudfront_web_acl_arn : null
  enable_waf                           = var.enable_waf
}


module "storage" {
  source = "./modules/storage"

  project_name           = var.project_name
  environment            = var.environment
  name_prefix            = local.name_prefix
  common_tags            = local.common_tags
  api_string_environment = local.api_string_environment
  api_secure_environment = var.api_secure_environment
}

module "databases" {
  source = "./modules/databases"

  name_prefix                     = local.name_prefix
  common_tags                     = local.common_tags
  project_name                    = var.project_name
  environment                     = var.environment
  database                        = var.database
  master_password                 = var.api_secure_environment["POSTGRES_PASSWORD"]
  cache                           = var.cache
  enable_rds_proxy                = var.enable_rds_proxy
  enable_rds_performance_insights = var.enable_rds_performance_insights
  app_security_group_id           = module.networking.app_security_group_id
  private_subnet_ids              = module.networking.private_subnet_ids
  postgres_security_group_id      = module.networking.postgres_security_group_id
  valkey_security_group_id        = module.networking.valkey_security_group_id
}


module "ecs_service" {
  source = "./modules/ecs_service"

  name_prefix               = local.name_prefix
  environment               = var.environment
  common_tags               = local.common_tags
  aws_region                = var.region
  container_architecture    = var.container_architecture
  enable_container_insights = var.enable_container_insights
  log_retention_in_days     = var.log_retention_in_days
  api                       = var.api
  worker                    = var.worker
  api_image_uri             = local.api_image_uri
  api_string_environment    = local.api_string_environment
  api_secrets               = local.api_secrets
  secure_parameter_arns     = local.secure_parameter_arns
  media_bucket_arn          = module.storage.media_bucket_arn
  public_subnet_ids         = module.networking.public_subnet_ids
  private_subnet_ids        = module.networking.private_subnet_ids
  app_security_group_id     = module.networking.app_security_group_id
  api_target_group_arn      = module.networking.api_target_group_arn
}


module "monitoring" {
  source = "./modules/monitoring"

  name_prefix             = local.name_prefix
  common_tags             = local.common_tags
  enabled                 = var.enable_monitoring_alarms
  alarm_email             = var.monitoring_alarm_email
  alb_arn_suffix          = module.networking.alb_arn_suffix
  target_group_arn_suffix = module.networking.api_target_group_arn_suffix
  ecs_cluster_name        = module.ecs_service.cluster_name
  ecs_service_name        = module.ecs_service.service_names.api
  ecs_min_task_count      = var.api.min_count
  rds_instance_id         = module.databases.database_instance_id
}
