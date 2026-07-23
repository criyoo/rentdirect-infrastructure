locals {
  api_string_environment = var.api_string_environment
  api_secure_environment = toset([
    for key, value in nonsensitive(var.api_secure_environment) : key if trimspace(value) != ""
  ])

  is_prod = var.environment == "prod"
}
