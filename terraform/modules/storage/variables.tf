terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "api_environment" {
  type = map(string)
}

variable "api_secure_environment" {
  type      = map(string)
  sensitive = true
}
