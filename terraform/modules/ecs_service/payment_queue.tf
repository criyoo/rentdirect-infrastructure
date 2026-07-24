data "aws_caller_identity" "current" {}

locals {
  payment_queue_environment = {
    PAYMENT_QUEUE_BACKEND                               = "sqs"
    PAYMENT_QUEUE_NAME                                  = aws_sqs_queue.payment.name
    PAYMENT_QUEUE_URL                                   = aws_sqs_queue.payment.url
    PAYMENT_QUEUE_AWS_REGION                            = var.aws_region
    PAYMENT_QUEUE_WORKER_WAIT_SECONDS                   = tostring(var.payment_queue.receive_wait_time_seconds)
    PAYMENT_QUEUE_WORKER_MAX_MESSAGES                   = "10"
    PAYMENT_QUEUE_VISIBILITY_TIMEOUT_SECONDS            = tostring(var.payment_queue.visibility_timeout_seconds)
    PAYMENT_QUEUE_READY_PAYOUT_INTERVAL_SECONDS         = "900"
    PAYMENT_QUEUE_SUBSCRIPTION_RENEWAL_INTERVAL_SECONDS = "3600"
  }

  container_environment = merge(var.api_string_environment, local.payment_queue_environment)
}

resource "aws_kms_key" "payment_queue" {
  description             = "KMS key for ${var.name_prefix} payment queue messages"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.common_tags
}

resource "aws_kms_alias" "payment_queue" {
  name          = "alias/${var.name_prefix}-payment-queue"
  target_key_id = aws_kms_key.payment_queue.key_id
}

resource "aws_sqs_queue" "payment_dlq" {
  name                       = "${var.name_prefix}-payment-dlq"
  message_retention_seconds  = var.payment_queue.message_retention_seconds
  receive_wait_time_seconds  = var.payment_queue.receive_wait_time_seconds
  visibility_timeout_seconds = var.payment_queue.visibility_timeout_seconds
  kms_master_key_id          = aws_kms_key.payment_queue.key_id
  tags                       = var.common_tags
}

resource "aws_sqs_queue" "payment" {
  name                       = "${var.name_prefix}-payment-queue"
  message_retention_seconds  = var.payment_queue.message_retention_seconds
  receive_wait_time_seconds  = var.payment_queue.receive_wait_time_seconds
  visibility_timeout_seconds = var.payment_queue.visibility_timeout_seconds
  kms_master_key_id          = aws_kms_key.payment_queue.key_id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.payment_dlq.arn
    maxReceiveCount     = var.payment_queue.max_receive_count
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy" "task_payment_queue" {
  name = "${var.name_prefix}-task-payment-queue"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          aws_sqs_queue.payment.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.payment_queue.arn
      }
    ]
  })
}

resource "aws_scheduler_schedule_group" "payment" {
  name = "${var.name_prefix}-payment"
  tags = var.common_tags
}

resource "aws_iam_role" "payment_scheduler" {
  name = "${var.name_prefix}-payment-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "payment_scheduler_queue" {
  name = "${var.name_prefix}-payment-scheduler-queue"
  role = aws_iam_role.payment_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.payment.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.payment_queue.arn
      }
    ]
  })
}

resource "aws_scheduler_schedule" "ready_payouts" {
  name                         = "${var.name_prefix}-ready-payouts"
  group_name                   = aws_scheduler_schedule_group.payment.name
  schedule_expression          = var.payment_queue.ready_payout_schedule_expression
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_sqs_queue.payment.arn
    role_arn = aws_iam_role.payment_scheduler.arn
    input = jsonencode({
      task = "process_ready_payouts"
      payload = {
        source = "eventbridge_scheduler"
      }
    })

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 3
    }
  }
}

resource "aws_scheduler_schedule" "subscription_renewals" {
  name                         = "${var.name_prefix}-subscription-renewals"
  group_name                   = aws_scheduler_schedule_group.payment.name
  schedule_expression          = var.payment_queue.subscription_renewal_schedule_expression
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_sqs_queue.payment.arn
    role_arn = aws_iam_role.payment_scheduler.arn
    input = jsonencode({
      task = "process_subscription_renewals"
      payload = {
        source = "eventbridge_scheduler"
      }
    })

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 3
    }
  }
}
