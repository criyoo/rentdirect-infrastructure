# resource "aws_ssm_parameter" "app_string" {
#   for_each = local.api_string_environment

#   name      = "/${var.project_name}/${var.environment}/${each.key}"
#   type      = "String"
#   value     = each.value
#   overwrite = true
#   tags      = var.common_tags
# }

resource "aws_ssm_parameter" "app_secure" {
  for_each = local.api_secure_environment

  name      = "/${var.project_name}/${var.environment}/${each.value}"
  type      = "SecureString"
  value     = var.api_secure_environment[each.value] # use to manage sensitive values # used to manage the version of the sensitive values
  overwrite = true
  tags      = var.common_tags
}
