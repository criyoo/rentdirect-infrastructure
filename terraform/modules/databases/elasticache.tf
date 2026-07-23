resource "aws_elasticache_subnet_group" "this" {
  for_each   = var.cache.enabled ? { enabled = true } : {}
  name       = "${var.name_prefix}-valkey-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "random_password" "valkey_auth" {
  for_each = var.cache.enabled && var.cache.transit_encryption_enabled ? { enabled = true } : {}
  length   = 32
  special  = false
}

resource "aws_ssm_parameter" "valkey_auth_token" {
  for_each = var.cache.enabled && var.cache.transit_encryption_enabled ? { enabled = true } : {}
  name     = "/${var.project_name}/${var.environment}/VALKEY_AUTH_TOKEN"
  type     = "SecureString"
  value    = random_password.valkey_auth["enabled"].result
  tags     = var.common_tags
}

resource "aws_elasticache_replication_group" "valkey" {
  for_each = var.cache.enabled ? { enabled = true } : {}

  replication_group_id       = "${var.name_prefix}-valkey"
  description                = "RentDirect Valkey"
  engine                     = "valkey"
  engine_version             = var.cache.engine_version
  node_type                  = var.cache.node_type
  num_cache_clusters         = 1 + var.cache.replica_count
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this["enabled"].name
  security_group_ids         = [var.valkey_security_group_id]
  automatic_failover_enabled = var.cache.replica_count > 0
  cluster_mode               = var.cache.replica_count > 0 ? "enabled" : "disabled"
  multi_az_enabled           = var.cache.multi_az_enabled && var.cache.replica_count > 0
  at_rest_encryption_enabled = true
  auto_minor_version_upgrade = true
  transit_encryption_enabled = var.cache.transit_encryption_enabled
  auth_token                 = var.cache.transit_encryption_enabled ? random_password.valkey_auth["enabled"].result : null
  apply_immediately          = true

  tags = var.common_tags
}
