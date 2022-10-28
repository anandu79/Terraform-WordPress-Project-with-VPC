#######################################
# Bastion Security group
#######################################

resource "aws_security_group" "sg" {
  name_prefix = "${var.project}-${var.environment}-${var.sg_name}-"
  description = var.sg_description
  vpc_id      = var.sg_vpc
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.project}-${var.environment}-${var.sg_name}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
