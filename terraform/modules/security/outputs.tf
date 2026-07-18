output "cloudfront_certificate_arn" {
  description = "Validated ACM certificate ARN for the frontend CloudFront distribution in us-east-1."
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "alb_certificate_arn" {
  value = aws_acm_certificate_validation.alb.certificate_arn
}

output "cloudfront_web_acl_arn" {
  value = var.enabled ? aws_wafv2_web_acl.cloudfront["enabled"].arn : null
}

output "regional_web_acl_arn" {
  value = var.enabled ? aws_wafv2_web_acl.alb["enabled"].arn : null
}
