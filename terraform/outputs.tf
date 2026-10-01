# output "cluster_name" {
#   description = "ECS cluster name."
#   value       = module.ecs_service.cluster_name
# }

# output "database_endpoint" {
#   description = "Database endpoint used by the API (RDS Proxy when enabled)."
#   value       = module.databases.database_endpoint
# }

# output "region" {
#   description = "Primary AWS region."
#   value       = var.region
# }

# output "api_url" {
#   description = "Public API URL."
#   value       = module.networking.api_url
# }

# output "media_url" {
#   description = "Public media URL."
#   value       = module.networking.media_url
# }

# output "api_repository_url" {
#   description = "Backend ECR repository URL."
#   value       = module.storage.api_repository_url
# }

# output "cluster_name" {
#   description = "ECS cluster name."
#   value       = module.ecs_service.cluster_name
# }

# output "service_names" {
#   description = "ECS service names."
#   value       = module.ecs_service.service_names
# }

# output "migration_task_definition_arn" {
#   description = "Migration task definition."
#   value       = module.ecs_service.migration_task_definition_arn
# }

# output "public_subnet_ids" {
#   description = "Public subnet IDs."
#   value       = module.networking.public_subnet_ids
# }

# output "app_security_group_id" {
#   description = "Shared ECS service security group ID."
#   value       = module.networking.app_security_group_id
# }

# output "frontend_bucket_name" {
#   description = "Frontend static bucket name."
#   value       = module.storage.frontend_bucket_name
# }

# output "cloudfront_distribution" {
#   description = "CloudFront distribution ID for the frontend."
#   value       = module.networking.cloudfront_distribution
# }

# output "media_cloudfront_distribution_id" {
#   description = "CloudFront distribution ID for the media bucket."
#   value       = module.networking.media_cloudfront_distribution_id
# }

# output "frontend_url" {
#   description = "Public frontend URL."
#   value       = module.networking.frontend_url
# }

# output "api_url" {
#   description = "Public API URL."
#   value       = module.networking.api_url
# }

# output "media_url" {
#   description = "Public media URL."
#   value       = module.networking.media_url
# }


# output "payment_queue_url" {
#   description = "Payment processing SQS queue URL."
#   value       = module.ecs_service.payment_queue_url
# }

# output "payment_queue_arn" {
#   description = "Payment processing SQS queue ARN."
#   value       = module.ecs_service.payment_queue_arn
# }

# output "payment_queue_dlq_arn" {
#   description = "Payment processing SQS dead-letter queue ARN."
#   value       = module.ecs_service.payment_queue_dlq_arn
# }


output "static_egress_ip" {
  description = "Static outbound IP for ECS tasks; whitelist this IP with Flutterwave."
  value       = module.networking.static_egress_ip
}