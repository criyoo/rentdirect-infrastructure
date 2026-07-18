output "sns_topic_arn" {
  value = var.enabled ? aws_sns_topic.alarms["enabled"].arn : null
}
