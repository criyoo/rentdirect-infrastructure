resource "aws_secretsmanager_secret" "rds_proxy" {
  for_each = var.enable_rds_proxy ? { enabled = true } : {}
  name     = "${var.name_prefix}-rds-proxy-creds"
  tags     = var.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_proxy" {
  for_each  = var.enable_rds_proxy ? { enabled = true } : {}
  secret_id = aws_secretsmanager_secret.rds_proxy["enabled"].id
  secret_string = jsonencode({
    username = var.database.username
    password = var.master_password
  })
}

resource "aws_iam_role" "rds_proxy" {
  for_each = var.enable_rds_proxy ? { enabled = true } : {}
  name     = "${var.name_prefix}-rds-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "rds_proxy_secrets" {
  for_each = var.enable_rds_proxy ? { enabled = true } : {}
  name     = "${var.name_prefix}-rds-proxy-secrets"
  role     = aws_iam_role.rds_proxy["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [aws_secretsmanager_secret.rds_proxy["enabled"].arn]
    }]
  })
}

resource "aws_security_group" "rds_proxy" {
  for_each    = var.enable_rds_proxy ? { enabled = true } : {}
  name        = "${var.name_prefix}-rds-proxy"
  description = "RDS Proxy access from ECS tasks"
  vpc_id      = data.aws_vpc.selected["enabled"].id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected["enabled"].cidr_block]
  }

  tags = var.common_tags
}

data "aws_vpc" "selected" {
  for_each = var.enable_rds_proxy ? { enabled = true } : {}
  id       = data.aws_subnet.private["enabled"].vpc_id
}

data "aws_subnet" "private" {
  for_each = var.enable_rds_proxy ? { enabled = true } : {}
  id       = var.private_subnet_ids[0]
}

resource "aws_security_group_rule" "postgres_from_proxy" {
  for_each                 = var.enable_rds_proxy ? { enabled = true } : {}
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.postgres_security_group_id
  source_security_group_id = aws_security_group.rds_proxy["enabled"].id
}

resource "aws_db_proxy" "this" {
  for_each               = var.enable_rds_proxy ? { enabled = true } : {}
  name                   = substr("${var.name_prefix}-proxy", 0, 60)
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.rds_proxy["enabled"].arn
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds_proxy["enabled"].id]
  require_tls            = true
  idle_client_timeout    = 1800
  debug_logging          = false

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_proxy["enabled"].arn
  }

  tags = var.common_tags
}

resource "aws_db_proxy_default_target_group" "this" {
  for_each      = var.enable_rds_proxy ? { enabled = true } : {}
  db_proxy_name = aws_db_proxy.this["enabled"].name

  connection_pool_config {
    max_connections_percent      = 90
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "this" {
  for_each               = var.enable_rds_proxy ? { enabled = true } : {}
  db_instance_identifier = aws_db_instance.postgres.identifier
  db_proxy_name          = aws_db_proxy.this["enabled"].name
  target_group_name      = aws_db_proxy_default_target_group.this["enabled"].name
}
