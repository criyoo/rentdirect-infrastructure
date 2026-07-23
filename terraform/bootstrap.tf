# resource "terraform_data" "backend_image_bootstrap" {
#   triggers_replace = {
#     repository_url           = module.storage.api_repository_url
#     application_hash         = local.api_application_hash
#     backend_bootstrap_script = filesha1("${path.module}/../scripts/bootstrap/backend.sh")
#     backend_deploy_script    = filesha1("${path.module}/../scripts/deploy/backend.sh")
#   }

#   depends_on = [module.storage]

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-lc"]
#     command     = "bash ${path.module}/../scripts/bootstrap/backend.sh"

#     environment = {
#       WORKSPACE   = terraform.workspace
#       REGION      = var.region
#       DOMAIN_NAME = var.domain_name
#     }
#   }
# }



# resource "terraform_data" "backend_service_stable" {
#   for_each = local.is_prod ? {} : { enabled = true }

#   triggers_replace = {
#     application_hash = local.api_application_hash
#     cluster_name     = module.ecs_service.cluster_name
#     api_service_name = module.ecs_service.service_names.api
#   }

#   depends_on = [module.ecs_service]

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-lc"]
#     command     = <<-EOT
#       set -euo pipefail
#       export AWS_PAGER=""
#       aws ecs wait services-stable \
#         --profile "$${AWS_WORKLOAD_PROFILE:-${terraform.workspace}-rentdirect}" \
#         --region "$${AWS_REGION}" \
#         --cluster "$${ECS_CLUSTER_NAME}" \
#         --services "$${ECS_SERVICE_NAME}"
#     EOT

#     environment = {
#       WORKSPACE        = terraform.workspace
#       AWS_REGION       = var.region
#       ECS_CLUSTER_NAME = module.ecs_service.cluster_name
#       ECS_SERVICE_NAME = module.ecs_service.service_names.api
#     }
#   }
# }

# resource "terraform_data" "backend_post_deployment_migration" {
#   for_each = local.is_prod ? {} : { enabled = true }

#   triggers_replace = {
#     application_hash              = local.api_application_hash
#     migration_script              = filesha1("${path.module}/../scripts/migrate.sh")
#     admin_script                  = filesha1("${path.module}/../scripts/create-admin-user.sh")
#     cluster_name                  = module.ecs_service.cluster_name
#     migration_task_definition_arn = module.ecs_service.migration_task_definition_arn
#     public_subnet_ids             = join(",", module.networking.public_subnet_ids)
#     app_security_group_id         = module.networking.app_security_group_id
#   }

#   depends_on = [terraform_data.backend_service_stable]

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-lc"]
#     command     = "bash ${path.module}/../scripts/migrate.sh"

#     environment = {
#       PROJECT_NAME                     = local.project_name
#       WORKSPACE                        = terraform.workspace
#       ENVIRONMENT                      = var.environment
#       AWS_REGION                       = var.region
#       ECS_CLUSTER_NAME                 = module.ecs_service.cluster_name
#       MIGRATION_TASK_DEFINITION        = module.ecs_service.migration_task_definition_arn
#       MIGRATION_LOG_GROUP              = "/ecs/${local.name_prefix}/migration"
#       PUBLIC_SUBNET_IDS                = join(",", module.networking.public_subnet_ids)
#       APP_SECURITY_GROUP_ID            = module.networking.app_security_group_id
#       ENSURE_SUPERUSER_AFTER_MIGRATION = "1"
#       ADMIN_PASSWORD                   = var.api_secure_environment.ADMIN_PASSWORD
#       MIGRATE_ON_STARTUP               = local.migrate_on_startup
#       SEED_DEMO_ACCOUNTS               = local.seed_demo_accounts
#       DJANGO_SECRET_KEY                = var.api_secure_environment.DJANGO_SECRET_KEY
#     }
#   }
# }


# resource "terraform_data" "frontend_assets_bootstrap" {
#   triggers_replace = {
#     bucket_name      = module.storage.frontend_bucket_name
#     application_hash = local.web_application_hash
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-lc"]
#     command     = "bash ${path.module}/../scripts/bootstrap/frontend.sh"
#     environment = {
#       PROJECT_NAME = local.project_name
#       WORKSPACE    = terraform.workspace
#       ENVIRONMENT  = var.environment
#       AWS_REGION   = var.region
#     }
#   }
#   depends_on = [module.storage]
# }


# resource "terraform_data" "frontend_cache_invalidation" {
#   triggers_replace = {
#     application_hash = local.web_application_hash
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-lc"]
#     command     = "bash ${path.module}/../scripts/deploy/invalidate_frontend.sh"
#     environment = {
#       WORKSPACE   = terraform.workspace
#       REGION      = var.region
#       DOMAIN_NAME = var.domain_name
#     }
#   }
#   depends_on = [
#     terraform_data.frontend_assets_bootstrap,
#     module.networking.cloudfront_distribution
#   ]
# }
