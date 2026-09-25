resource "aws_wafv2_web_acl_association" "alb" {
  for_each = local.waf_enabled ? { enabled = true } : {}

  resource_arn = module.networking.alb_arn
  web_acl_arn  = module.security.regional_web_acl_arn
}
