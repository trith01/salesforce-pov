

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.token
  assume_role {
    role_arn = "arn:aws:iam::139717516944:role/AccountUser"
  }
}



# VPCs

resource "aws_vpc" "vpc-1" {
  cidr_block = "10.3.0.0/16"
  tags = {
    Name     = "${var.scenario}-vpc1-mna"
    scenario = "${var.scenario}"
    env      = "mna"
  }
}


# Subnets

resource "aws_subnet" "vpc-1-sub-a" {
  vpc_id            = aws_vpc.vpc-1.id
  cidr_block        = "10.3.1.0/24"
  availability_zone = var.az1

  tags = {
    Name = "${aws_vpc.vpc-1.tags.Name}-sub-a"
  }
}

# resource "aws_subnet" "vpc-1-sub-b" {
#   vpc_id            = aws_vpc.vpc-1.id
#   cidr_block        = "10.3.2.0/24"
#   availability_zone = var.az2
# 
#   tags = {
#     Name = "${aws_vpc.vpc-1.tags.Name}-sub-b"
#   }
# }


# Internet Gateway

resource "aws_internet_gateway" "vpc-1-igw" {
  vpc_id = aws_vpc.vpc-1.id

  tags = {
    Name     = "vpc-1-igw"
    scenario = "${var.scenario}"
  }
}


resource "aws_main_route_table_association" "main-rt-vpc-1" {
  vpc_id         = aws_vpc.vpc-1.id
  route_table_id = aws_route_table.vpc-1-rtb.id
}

resource "aws_route_table" "vpc-1-rtb" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.pov-aws-tgw.id
  }

  route {
    cidr_block         = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-1-igw.id
  }

  tags = {
    Name     = "vpc-1-rtb"
    env      = "mna"
    scenario = "${var.scenario}"
  }
  depends_on = [aws_ec2_transit_gateway.pov-aws-tgw]
}






resource "aws_ec2_transit_gateway" "pov-aws-tgw" {
  description                     = "Transit Gateway testing scenario with VPC, 1 subnets each"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name     = "${var.scenario}"
    scenario = "${var.scenario}"
  }
}



resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-att-vpc-1" {
  subnet_ids                                      = ["${aws_subnet.vpc-1-sub-a.id}"]
  transit_gateway_id                              = aws_ec2_transit_gateway.pov-aws-tgw.id
  vpc_id                                          = aws_vpc.vpc-1.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name     = "tgw-att-vpc1"
    scenario = "${var.scenario}"
  }
  depends_on = [aws_ec2_transit_gateway.pov-aws-tgw]
}





resource "aws_ec2_transit_gateway_route_table" "tgw-mna-rt" {
  transit_gateway_id = aws_ec2_transit_gateway.pov-aws-tgw.id
  tags = {
    Name     = "tgw-mna-rt"
    scenario = "${var.scenario}"
  }
  depends_on = [aws_ec2_transit_gateway.pov-aws-tgw]
}



resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-vpc-1-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-mna-rt.id
}



resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-mna-to-vpc-1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-att-vpc-1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-mna-rt.id
}


output "public_key" {
  value       = module.aws_key_pair.public_key
  description = "Content of the generated public key"
}
