resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pub-subnet["ap-south-1a"].id

  tags = {
    Name = "${var.name_prefix}-ngw"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "pub-subnet" {
  for_each=var.public_subnets
  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value
  availability_zone = each.key

  tags = {
    Name = "${var.name_prefix}-${each.key}-pubsubnet"
  }
}

resource "aws_subnet" "priv-subnet" {
  for_each=var.private_subnets
  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value
  availability_zone = each.key

  tags = {
    Name = "${var.name_prefix}-${each.key}-privsubnet"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = var.eip_name
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.name_prefix}-publicrt"
  }
}

resource "aws_route_table_association" "public-rt-assoc" {
  for_each = var.public_subnets  
  subnet_id      = aws_subnet.pub-subnet[each.key].id
  route_table_id = aws_route_table.public-rt.id
}


resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private-rt-assoc" {
    for_each = var.private_subnets
  subnet_id      = aws_subnet.priv-subnet[each.key].id
  route_table_id = aws_route_table.private-rt.id
}
