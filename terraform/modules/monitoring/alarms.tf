resource "aws_sns_topic" "alarms" {
  for_each = var.enabled ? { enabled = true } : {}
  name     = "${var.name_prefix}-alarms"
  tags     = var.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each  = var.enabled && trimspace(var.alarm_email) != "" ? { enabled = true } : {}
  topic_arn = aws_sns_topic.alarms["enabled"].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  for_each            = var.enabled ? { enabled = true } : {}
  alarm_name          = "${var.name_prefix}-alb-target-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_description   = "RentDirect ALB target 5xx responses exceeded threshold."
  alarm_actions       = [aws_sns_topic.alarms["enabled"].arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_low" {
  for_each            = var.enabled ? { enabled = true } : {}
  alarm_name          = "${var.name_prefix}-ecs-running-tasks-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_min_task_count
  treat_missing_data  = "breaching"
  alarm_description   = "RentDirect ECS service has fewer running tasks than expected."
  alarm_actions       = [aws_sns_topic.alarms["enabled"].arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  for_each            = var.enabled ? { enabled = true } : {}
  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_description   = "RentDirect RDS CPU utilization exceeded threshold."
  alarm_actions       = [aws_sns_topic.alarms["enabled"].arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}
