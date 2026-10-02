resource "aws_subnet" "public" {
  for_each = {
    for index, az in var.availability_zones :
    az => {
      az   = az
      cidr = cidrsubnet(var.vpc_cidr, 4, index)
    }
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-${each.value.az}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = {
    for index, az in var.availability_zones :
    az => {
      az   = az
      cidr = cidrsubnet(var.vpc_cidr, 4, index + 8)
    }
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-${each.value.az}"
    Tier = "private"
  })
}
