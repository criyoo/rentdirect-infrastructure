data "aws_route53_zone" "main" {
  provider = aws.root

  name         = var.root_domain_name
  private_zone = false
}

data "aws_availability_zones" "available" {
  state = "available"
}


# resource "aws_route53_zone" "main" {
#   provider = aws.root

#   name = var.root_domain_name

#   tags = {
#     Environment = "root"
#   }
# }
