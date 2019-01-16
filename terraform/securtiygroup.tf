resource "aws_security_group" "public_limited_sg" {
  vpc_id      = "${aws_vpc.cloud_den.id}"
  name        = "public_limited_sg"
  description = "security group for enbling selective egress and ingress traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["91.64.210.175/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "public_limited_sg"
  }
}

resource "aws_security_group" "private_dmz_sg" {
  vpc_id      = "${aws_vpc.cloud_den.id}"
  name        = "private_dmz_sg"
  description = "security group for private dmz with selective egress and ingress traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "TCP"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "UDP"
    cidr_blocks = ["10.10.0.0/16"]
  }

  tags {
    Name = "private_dmz_sg"
  }
}
