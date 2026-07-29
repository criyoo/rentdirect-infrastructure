locals {
  runtime_platform = {
    cpu_architecture        = var.container_architecture
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.name_prefix}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.api.cpu)
  memory                   = tostring(var.api.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    cpu_architecture        = local.runtime_platform.cpu_architecture
    operating_system_family = local.runtime_platform.operating_system_family
  }

  container_definitions = jsonencode([{
    name      = "api"
    image     = var.api_image_uri
    essential = true
    portMappings = [{
      containerPort = var.api.port
      hostPort      = var.api.port
      protocol      = "tcp"
    }]
    environment = [for key, value in local.container_environment : {
      name  = key
      value = value
    }]
    secrets = [for key, value in var.api_secrets : {
      name      = key
      valueFrom = value
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health/ready', timeout=3)\""]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
  }])

  tags = var.common_tags
}



resource "aws_ecs_task_definition" "payout_worker" {
  family                   = "${var.name_prefix}-payout-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.worker.cpu)
  memory                   = tostring(var.worker.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    cpu_architecture        = local.runtime_platform.cpu_architecture
    operating_system_family = local.runtime_platform.operating_system_family
  }

  container_definitions = jsonencode([{
    name      = "payout-worker"
    image     = var.api_image_uri
    essential = true
    command   = ["python", "manage.py", "payment_queue_worker"]
    environment = [for key, value in local.container_environment : {
      name  = key
      value = value
    }]
    secrets = [for key, value in var.api_secrets : {
      name      = key
      valueFrom = value
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.payout_worker.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "python -c \"import os; os.kill(1, 0)\""]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
  }])

  tags = var.common_tags
}



resource "aws_ecs_task_definition" "migration" {
  family                   = "${var.name_prefix}-migration"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.worker.cpu)
  memory                   = tostring(var.worker.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    cpu_architecture        = local.runtime_platform.cpu_architecture
    operating_system_family = local.runtime_platform.operating_system_family
  }

  container_definitions = jsonencode([{
    name      = "migration"
    image     = var.api_image_uri
    essential = true
    command   = ["sh", "-c", "python manage.py migrate"]
    environment = [for key, value in local.container_environment : {
      name  = key
      value = value
    }]
    secrets = [for key, value in var.api_secrets : {
      name      = key
      valueFrom = value
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.migration.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = var.common_tags
}
