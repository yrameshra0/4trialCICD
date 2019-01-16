resource "aws_vpc" "cloud_den" {
  cidr_block           = "10.10.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"

  tags {
    Name = "cloud_den"
  }
}

# Subnets

resource "aws_subnet" "public_sn_1" {
  vpc_id                  = "${aws_vpc.cloud_den.id}"
  cidr_block              = "10.10.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"

  tags {
    Name = "public_sn"
  }
}

resource "aws_subnet" "public_sn_2" {
  vpc_id                  = "${aws_vpc.cloud_den.id}"
  cidr_block              = "10.10.20.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1b"

  tags {
    Name = "public_sn"
  }
}

resource "aws_subnet" "private_sn_1" {
  vpc_id                  = "${aws_vpc.cloud_den.id}"
  cidr_block              = "10.10.30.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-south-1a"

  tags {
    Name = "private_sn_1"
  }
}

resource "aws_subnet" "private_sn_2" {
  vpc_id                  = "${aws_vpc.cloud_den.id}"
  cidr_block              = "10.10.40.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "ap-south-1b"

  tags {
    Name = "private_sn_2"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "outbound_internet_gw" {
  vpc_id = "${aws_vpc.cloud_den.id}"

  tags {
    Name = "outbound_internet_gw"
  }
}

# Network Access Translation

resource "aws_eip" "nat_eip_1" {
  vpc = true
}

resource "aws_eip" "nat_eip_2" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = "${aws_eip.nat_eip_1.id}"
  subnet_id     = "${aws_subnet.public_sn_1.id}"
  depends_on    = ["aws_internet_gateway.outbound_internet_gw"]
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = "${aws_eip.nat_eip_2.id}"
  subnet_id     = "${aws_subnet.public_sn_2.id}"
  depends_on    = ["aws_internet_gateway.outbound_internet_gw"]
}

# Route Table

resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.cloud_den.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.outbound_internet_gw.id}"
  }

  tags {
    Name = "public_rt"
  }
}

resource "aws_route_table" "private_rt_1" {
  vpc_id = "${aws_vpc.cloud_den.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat_gw_1.id}"
  }

  tags {
    Name = "private_rt_1"
  }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = "${aws_vpc.cloud_den.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat_gw_2.id}"
  }

  tags {
    Name = "private_rt_2"
  }
}

# Route Table Association

resource "aws_route_table_association" "public_rt_association_1" {
  subnet_id      = "${aws_subnet.public_sn_1.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_route_table_association" "public_rt_association_2" {
  subnet_id      = "${aws_subnet.public_sn_2.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_route_table_association" "private_rt_association_1" {
  subnet_id      = "${aws_subnet.private_sn_1.id}"
  route_table_id = "${aws_route_table.private_rt_1.id}"
}

resource "aws_route_table_association" "private_rt_association_2" {
  subnet_id      = "${aws_subnet.private_sn_2.id}"
  route_table_id = "${aws_route_table.private_rt_2.id}"
}
