resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.name_prefix}/api"
  retention_in_days = var.log_retention_in_days
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "payout_worker" {
  name              = "/ecs/${var.name_prefix}/payout_worker"
  retention_in_days = var.log_retention_in_days
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "migration" {
  name              = "/ecs/${var.name_prefix}/migration"
  retention_in_days = var.log_retention_in_days
  tags              = var.common_tags
}
