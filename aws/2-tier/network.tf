resource "aws_vpc" "AdopVPC" {
  cidr_block = "172.31.0.0/16"
  tags {
    Name = "ADOPVPCTerraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.AdopVPC.id}"

  tags {
    Name = "mainIGW"
  }
}

data "aws_route_table" "selected" {
  vpc_id = "${aws_vpc.AdopVPC.id}"
  depends_on = ["aws_internet_gateway.igw"]
}

##### Elastic IPs
resource "aws_eip" "NATGw1Eip" {
  vpc                       = true
  depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_eip" "NATGw2Eip" {
  vpc                       = true
  depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_eip" "VPNEip" {

  depends_on = ["aws_internet_gateway.igw"]
}

##### Subnets
resource "aws_subnet" "PublicSubnet1" {
  vpc_id = "${aws_vpc.AdopVPC.id}"
  cidr_block = "172.31.0.0/28"
  map_public_ip_on_launch = true
  
  tags {
    Name = "PublicSubnet1"
  }

  depends_on = ["aws_internet_gateway.igw"]
}
resource "aws_subnet" "PublicSubnet2" {
  vpc_id = "${aws_vpc.AdopVPC.id}"
  cidr_block = "172.31.32.0/28"
  map_public_ip_on_launch = true
  
  tags {
    Name = "PublicSubnet2"
  }

  depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_subnet" "PrivateSubnet1" {
  vpc_id = "${aws_vpc.AdopVPC.id}"
  cidr_block = "172.31.64.0/28"
  map_public_ip_on_launch = false
  
  tags {
    Name = "AdopSubnet"
  }

  depends_on = ["aws_internet_gateway.igw"]
}


resource "aws_nat_gateway" "NATgw1" {
  allocation_id = "${aws_eip.NATGw1Eip.id}"
  subnet_id     = "${aws_subnet.PublicSubnet1.id}"

  tags {
    Name = "gw NAT 1"
  }
}
resource "aws_nat_gateway" "NATgw2" {
  allocation_id = "${aws_eip.NATGw2Eip.id}"
  subnet_id     = "${aws_subnet.PublicSubnet2.id}"

  tags {
    Name = "gw NAT 2"
  }
}