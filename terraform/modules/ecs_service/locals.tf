locals {
  payment_queue_environment = {
    PAYMENT_QUEUE_BACKEND                                   = "sqs"
    PAYMENT_QUEUE_NAME                                      = aws_sqs_queue.payment.name
    PAYMENT_QUEUE_URL                                       = aws_sqs_queue.payment.url
    PAYMENT_QUEUE_AWS_REGION                                = var.aws_region
    PAYMENT_QUEUE_WORKER_WAIT_SECONDS                       = tostring(var.payment_queue.receive_wait_time_seconds)
    PAYMENT_QUEUE_WORKER_MAX_MESSAGES                       = "10"
    PAYMENT_QUEUE_VISIBILITY_TIMEOUT_SECONDS                = tostring(var.payment_queue.visibility_timeout_seconds)
    PAYMENT_QUEUE_READY_PAYOUT_INTERVAL_SECONDS             = "900"
    PAYMENT_QUEUE_SUBSCRIPTION_RENEWAL_INTERVAL_SECONDS     = "3600"
    PAYMENT_QUEUE_RECONCILIATION_INTERVAL_SECONDS           = "300"
    PAYMENT_QUEUE_TENANCY_RENEWAL_REMINDER_INTERVAL_SECONDS = "3600"
  }

  container_environment = merge(var.api_string_environment, local.payment_queue_environment)
}
