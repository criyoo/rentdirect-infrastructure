output "database_endpoint" {
  value = var.enable_rds_proxy ? aws_db_proxy.this["enabled"].endpoint : aws_db_instance.postgres.address
}

output "database_instance_id" {
  value = aws_db_instance.postgres.id
}

output "valkey_url" {
  value = var.cache.enabled ? format(
    "%s://%s:6379/0",
    var.cache.transit_encryption_enabled ? "rediss" : "redis",
    coalesce(
      aws_elasticache_replication_group.valkey["enabled"].primary_endpoint_address,
      aws_elasticache_replication_group.valkey["enabled"].configuration_endpoint_address
    )
  ) : ""
}

output "valkey_auth_parameter_arn" {
  value = var.cache.enabled && var.cache.transit_encryption_enabled ? aws_ssm_parameter.valkey_auth_token["enabled"].arn : null
}
