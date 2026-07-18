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

variable "common_tags" {
  type = map(string)
}

variable "enabled" {
  type = bool
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_min_task_count" {
  type    = number
  default = 1
}

variable "rds_instance_id" {
  type = string
}
