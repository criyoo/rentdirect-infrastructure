# resource "aws_route53_record" "hostinger_email_mx" {
#   provider = aws.root

#   count = var.manage_root_email_dns ? 1 : 0

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = var.root_domain_name
#   type            = "MX"
#   ttl             = var.hostinger_email_dns.ttl

#   records = [
#     for record in var.hostinger_email_dns.mx_records :
#     "${record.priority} ${record.value}"
#   ]
# }

# resource "aws_route53_record" "hostinger_email_spf" {
#   provider = aws.root
#   count    = var.manage_root_email_dns ? 1 : 0

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = var.root_domain_name
#   type            = "TXT"
#   ttl             = 3600 #var.hostinger_email_dns.ttl
#   records         = [var.hostinger_email_dns.spf_record]
# }

# resource "aws_route53_record" "hostinger_email_dmarc" {
#   provider = aws.root
#   count    = var.manage_root_email_dns ? 1 : 0

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = "_dmarc.${var.root_domain_name}"
#   type            = "TXT"
#   ttl             = 3600 #var.hostinger_email_dns.ttl
#   records         = [var.hostinger_email_dns.dmarc_record]
# }

# resource "aws_route53_record" "hostinger_email_dkim" {
#   provider = aws.root

#   for_each = var.manage_root_email_dns ? var.hostinger_email_dns.dkim_records : {}

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = "${each.key}.${var.root_domain_name}"
#   type            = "CNAME"
#   ttl             = 300 #var.hostinger_email_dns.ttl
#   records         = [each.value]
# }
