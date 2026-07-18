output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_names" {
  value = {
    api           = aws_ecs_service.api.name
    payout_worker = aws_ecs_service.payout_worker.name
  }
}

output "migration_task_definition_arn" {
  value = aws_ecs_task_definition.migration.arn
}
