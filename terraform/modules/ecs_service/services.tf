resource "aws_ecs_service" "api" {
  name            = "${var.name_prefix}-api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 180

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.api_target_group_arn
    container_name   = "api"
    container_port   = var.api.port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.common_tags
}

resource "aws_ecs_service" "payout_worker" {
  name            = "${var.name_prefix}-payout-worker"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.payout_worker.arn
  desired_count   = var.worker.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = false
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.common_tags
}
