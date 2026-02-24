resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

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
resource "aws_eip" "eip" {
  for_each = var.public_subnets
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-${each.key}-eip"
  }
}

resource "aws_nat_gateway" "ngw" {
  for_each = var.public_subnets
  allocation_id = aws_eip.eip[each.key].id
  subnet_id     = aws_subnet.pub-subnet[each.key].id

  tags = {
    Name = "${var.name_prefix}-${each.key}-ngw"
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
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "priv-subnet" {
  for_each=var.private_subnets
  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value
  availability_zone = each.key

  tags = {
    Name = "${var.name_prefix}-${each.key}-privsubnet"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
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
  for_each = var.private_subnets
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[each.key].id
  }
  tags = {
    Name = "${var.name_prefix}-${each.key}-private-rt"
  }
}

resource "aws_route_table_association" "private-rt-assoc" {
  for_each = var.private_subnets
  subnet_id      = aws_subnet.priv-subnet[each.key].id
  route_table_id = aws_route_table.private-rt[each.key].id
}
