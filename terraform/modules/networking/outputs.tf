output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_arn_suffix" {
  value = aws_lb.this.arn_suffix
}

output "api_target_group_arn_suffix" {
  value = aws_lb_target_group.api.arn_suffix
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "api_target_group_arn" {
  value = aws_lb_target_group.api.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "frontend_url" {
  value = "https://${var.domain_name}"
}

output "media_domain_name" {
  value = "media.${var.domain_name}"
}

output "media_url" {
  value = "https://media.${var.domain_name}"
}

output "api_url" {
  value = trimspace(var.api_domain_name) != "" ? "https://${var.api_domain_name}" : "https://${var.domain_name}/api/"
}

output "cloudfront_distribution" {
  value = aws_cloudfront_distribution.this
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.this.arn
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "media_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.media.id
}

output "media_cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.media.domain_name
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "postgres_security_group_id" {
  value = aws_security_group.postgres.id
}

output "valkey_security_group_id" {
  value = aws_security_group.valkey.id
}
