terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "aws_region" {
  type = string
}

variable "container_architecture" {
  type = string
}

variable "enable_container_insights" {
  type = bool
}

variable "log_retention_in_days" {
  type = number
}

variable "api" {
  type = object({
    cpu           = number
    memory        = number
    port          = number
    desired_count = number
    min_count     = number
    max_count     = number
    cpu_target    = number
  })
}

variable "worker" {
  type = object({
    cpu           = number
    memory        = number
    desired_count = number
  })
}

variable "payment_queue" {
  type = object({
    visibility_timeout_seconds                 = number
    message_retention_seconds                  = number
    max_receive_count                          = number
    receive_wait_time_seconds                  = number
    ready_payout_schedule_expression           = string
    subscription_renewal_schedule_expression   = string
    pending_reconciliation_schedule_expression = string
  })
}

variable "api_image_uri" {
  type = string
}

variable "api_string_environment" {
  type = map(string)
}

variable "api_secrets" {
  type = map(string)
}

variable "secure_parameter_arns" {
  type = list(string)
}

variable "media_bucket_arn" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "api_target_group_arn" {
  type = string
}
