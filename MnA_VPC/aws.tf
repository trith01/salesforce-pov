provider "aws" {
  region = "us-west-2"
  access_key = var.sfaccess_key
    secret_key = var.sfsecret_key
    token = var.sftoken
    assume_role {
      role_arn    = ""
    }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.3.0.0/16"
  tags = {
    Name = "tableau5MnA"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.3.0.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]
  tags = {
    Name = "tableau5MnA-subnet"
  }
}

resource "aws_subnet" "subnet_ha" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.3.1.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[1]
  tags = {
    Name = "tableau5MnA-subnet-ha"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tableau5MnA-igw"
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "tableau5MnA-rtb"
  }
}

resource "aws_route_table_association" "rtb_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rtb_association_ha" {
  subnet_id      = aws_subnet.subnet_ha.id
  route_table_id = aws_route_table.rtb.id
}

resource "tls_private_key" "keypair_material" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = var.keypair
  public_key = tls_private_key.keypair_material.public_key_openssh
}
