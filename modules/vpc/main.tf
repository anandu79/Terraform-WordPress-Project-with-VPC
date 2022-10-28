#########################################
#VPC CREATION
#########################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

#########################################
#Internet gateway creation
#########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

#########################################
# creating 3 public subnets
#########################################

resource "aws_subnet" "public" {
  count                   = var.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 0)
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.environment}-public-${1 + count.index}"
  }
}

#########################################
# creating 3 private subnets
#########################################

resource "aws_subnet" "private" {
  count                   = var.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + var.subnets)
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.environment}-private-${1 + count.index}"
  }
}

#########################################
# elastic IP for NAT gateway
#########################################

resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "${var.project}-${var.environment}-nat"
  }
}

#########################################
# NAT gateway creation
#########################################

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

#########################################
#route table for public subnet
#########################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-public"
  }
}

#########################################
#route table for private subnet
#########################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}

#########################################
#route table association of public subnets to public route table
#########################################

resource "aws_route_table_association" "public_subnbet" {
  count          = var.subnets
  subnet_id      = aws_subnet.public["${count.index}"].id
  route_table_id = aws_route_table.public.id
}

#########################################
#route table association of private subnets to private route table
#########################################

resource "aws_route_table_association" "private_subnet" {
  count          = var.subnets
  subnet_id      = aws_subnet.private["${count.index}"].id
  route_table_id = aws_route_table.private.id
}
