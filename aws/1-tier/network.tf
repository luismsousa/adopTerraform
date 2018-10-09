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


resource "aws_eip" "ADOPEIP" {
  instance = "${aws_instance.ADOPInstance.id}"

  depends_on = ["aws_internet_gateway.igw"]
  depends_on = ["aws_instance.ADOPInstance"]
}

resource "aws_route" "route" {
  route_table_id            = "${data.aws_route_table.selected.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}
resource "aws_subnet" "AdopSubnet" {
  vpc_id = "${aws_vpc.AdopVPC.id}"
  cidr_block = "172.31.64.0/28"
  map_public_ip_on_launch = true
  
  tags {
    Name = "AdopSubnet"
  }

  depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_security_group" "ADOPSecurityGroup" {
  name        = "ADOPSecurityGroup"
  description = "Allow ADOP inbound traffic"
  vpc_id     = "${aws_vpc.AdopVPC.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 25826
    to_port     = 25826
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "ADOPSecurityGroup"
  }
}

