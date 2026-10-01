resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = var.common_tags
}

resource "aws_db_instance" "postgres" {
  identifier                            = "${var.name_prefix}-postgres"
  engine                                = "postgres"
  engine_version                        = var.database.engine_version
  instance_class                        = var.database.instance_class
  allocated_storage                     = var.database.allocated_storage
  max_allocated_storage                 = var.database.max_allocated_storage
  storage_type                          = "gp3"
  db_name                               = var.database.name
  username                              = var.database.username
  password                              = var.master_password
  db_subnet_group_name                  = aws_db_subnet_group.this.name
  vpc_security_group_ids                = [var.postgres_security_group_id]
  backup_retention_period               = var.database.backup_retention_period
  multi_az                              = var.database.multi_az
  deletion_protection                   = var.database.deletion_protection
  skip_final_snapshot                   = var.database.skip_final_snapshot
  final_snapshot_identifier             = "${var.name_prefix}-postgres-${random_string.random.result}"
  auto_minor_version_upgrade            = true
  publicly_accessible                   = false
  storage_encrypted                     = true
  performance_insights_enabled          = var.enable_rds_performance_insights
  performance_insights_retention_period = var.enable_rds_performance_insights ? 7 : null

  tags = var.common_tags
}

resource "random_string" "random" {
  length           = 8
  special          = true
  override_special = "-"
}
