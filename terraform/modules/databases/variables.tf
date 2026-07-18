terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "project_name" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "environment" {
  type = string
}

variable "database" {
  type = object({
    instance_class          = string
    allocated_storage       = number
    max_allocated_storage   = number
    backup_retention_period = number
    multi_az                = bool
    deletion_protection     = bool
    skip_final_snapshot     = bool
    engine_version          = string
    name                    = string
    username                = string
  })
}

variable "master_password" {
  type      = string
  sensitive = true
}

variable "enable_rds_proxy" {
  type    = bool
  default = false
}

variable "enable_rds_performance_insights" {
  type    = bool
  default = false
}

variable "app_security_group_id" {
  type    = string
  default = ""
}

variable "cache" {
  type = object({
    enabled                    = bool
    node_type                  = string
    engine_version             = string
    replica_count              = number
    multi_az_enabled           = bool
    transit_encryption_enabled = optional(bool, false)
  })
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "postgres_security_group_id" {
  type = string
}

variable "valkey_security_group_id" {
  type = string
}
