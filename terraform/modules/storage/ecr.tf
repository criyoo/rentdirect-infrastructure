resource "aws_ecr_repository" "api" {
  name                 = "${var.name_prefix}-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = local.is_prod ? false : true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.common_tags
}
