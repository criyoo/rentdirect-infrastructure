# resource "aws_route53_record" "godaddy_email_mx" {
#   provider = aws.root

#   # count    = var.manage_root_email_dns ? 1 : 0
#   for_each = var.manage_root_email_dns ? { main = true } : {}

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = var.root_domain_name
#   type            = "MX"
#   ttl             = var.godaddy_email_dns.mx_ttl

#   records = [
#     for record in var.godaddy_email_dns.mx_records :
#     "${record.priority} ${record.value}"
#   ]
# }


# resource "aws_route53_record" "godaddy_email_spf" {
#   provider = aws.root
#   # count    = var.manage_root_email_dns ? 1 : 0
#   for_each = var.manage_root_email_dns ? { main = true } : {}

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = var.root_domain_name
#   type            = "TXT"
#   ttl             = var.godaddy_email_dns.spf_ttl
#   records         = [for record in var.godaddy_email_dns.spf_record : "${record}"]
# }


# resource "aws_route53_record" "godaddy_email_dmarc" {
#   provider = aws.root
#   # count    = var.manage_root_email_dns ? 1 : 0
#   for_each = var.manage_root_email_dns ? { main = true } : {}

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = "_dmarc.${var.root_domain_name}"
#   type            = "TXT"
#   ttl             = var.godaddy_email_dns.dmarc_ttl
#   records         = [var.godaddy_email_dns.dmarc_record]
# }


# resource "aws_route53_record" "godaddy_email_srv" {
#   provider = aws.root

#   for_each = var.manage_root_email_dns ? var.godaddy_email_dns.srv_record : {}

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = "${each.key}.${var.root_domain_name}"
#   type            = "SRV"
#   ttl             = var.godaddy_email_dns.srv_ttl
#   records         = [each.value]
# }


# resource "aws_route53_record" "godaddy_email_dkim" {
#   provider = aws.root

#   for_each = var.manage_root_email_dns ? var.godaddy_email_dns.dkim_records : {}

#   allow_overwrite = true
#   zone_id         = local.route53_zone_id
#   name            = "${each.key}.${var.root_domain_name}"
#   type            = "CNAME"
#   ttl             = var.godaddy_email_dns.dkim_ttl
#   records         = [each.value]
# }
