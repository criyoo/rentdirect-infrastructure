terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.root, aws.acm]
    }
  }
}

variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "root_domain_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "api_domain_name" {
  type    = string
  default = ""
}

variable "hosted_zone_id" {
  type = string
}

variable "enabled" {
  type = bool
}

variable "rate_limit" {
  description = "Maximum requests per 5 minutes per IP for auth endpoints."
  type        = number
  default     = 2000
}

variable "cloudfront_distribution" {
  type = any
}
