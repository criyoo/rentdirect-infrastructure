# Cloudfront Certificate
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.acm

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "aws_route53_record" "cloudfront_validation" {
  provider = aws.root

  for_each = {
    for option in aws_acm_certificate.cloudfront.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = var.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.acm

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]
}

# ALB Certificate
resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = trimspace(var.api_domain_name) != "" && var.api_domain_name != var.domain_name ? [var.api_domain_name] : []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "aws_route53_record" "alb_validation" {
  provider = aws.root

  for_each = {
    for option in aws_acm_certificate.alb.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_validation : record.fqdn]
}
