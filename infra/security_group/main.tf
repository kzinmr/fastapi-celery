variable "name" {}
variable "vpc_id" {}
variable "description" {}
variable "tags" {
  type = map(string)
}

resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = var.vpc_id
  description = var.description
  tags = var.tags
}
resource "aws_vpc_security_group_egress_rule" "allow_all_egress_ipv4" {
  security_group_id = aws_security_group.default.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
resource "aws_vpc_security_group_egress_rule" "allow_all_egress_ipv6" {
  security_group_id = aws_security_group.default.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

output "security_group_id" {
  value = aws_security_group.default.id
}
