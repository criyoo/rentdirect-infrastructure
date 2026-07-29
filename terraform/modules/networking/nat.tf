resource "aws_eip" "egress" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-egress"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "egress" {
  allocation_id = aws_eip.egress.id
  subnet_id     = aws_subnet.public[keys(aws_subnet.public)[0]].id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-egress"
  })

  depends_on = [aws_internet_gateway.this]
}
