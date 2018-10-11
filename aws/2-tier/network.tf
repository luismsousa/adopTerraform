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


##### NAT Gateways

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

##### RouteTables

resource "aws_default_route_table" "defaultRT" {
  default_route_table_id = "${aws_vpc.AdopVPC.default_route_table_id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "default table"
  }
  
}

resource "aws_route_table_association" "publicRoute1" {
  subnet_id      = "${aws_subnet.PublicSubnet1.id}"
  route_table_id = "${aws_default_route_table.defaultRT.id}"
  
}

resource "aws_route_table_association" "publicRoute2" {
  subnet_id      = "${aws_subnet.PublicSubnet2.id}"
  route_table_id = "${aws_default_route_table.defaultRT.id}"
  
}

resource "aws_route_table" "privateRT" {
    route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = "${aws_nat_gateway.NATgw1.id}"
    }
  vpc_id = "${aws_vpc.AdopVPC.id}"

  tags {
    Name = "Private RT"
  }
  depends_on = ["aws_route_table_association.publicRoute1"]
}

resource "aws_route_table_association" "privateRTAssociation" {
    route_table_id = "${aws_route_table.privateRT.id}"
    subnet_id = "${aws_subnet.PrivateSubnet1.id}"
}



##### Security Groups

resource "aws_security_group" "ADOPSecurityGroup" {
  name        = "ADOPSecurityGroup"
  description = "Allow ADOP inbound traffic"
  vpc_id     = "${aws_vpc.AdopVPC.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.AdopVPC.cidr_block}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.AdopVPC.cidr_block}"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.AdopVPC.cidr_block}"]
  }
  ingress {
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.AdopVPC.cidr_block}"]
  }
  ingress {
    from_port   = 25826
    to_port     = 25826
    protocol    = "udp"
    cidr_blocks = ["${aws_vpc.AdopVPC.cidr_block}"]
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

resource "aws_security_group" "ELBSecurityGroup" {
  name        = "ELBSecurityGroup"
  description = "Public Proxy Security Group"
  vpc_id     = "${aws_vpc.AdopVPC.id}"

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

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "ELBSecurityGroup"
  }
}

resource "aws_security_group" "ProxySecurityGroup" {
  name        = "ProxySecurityGroup"
  description = "Proxy Security Group"
  vpc_id     = "${aws_vpc.AdopVPC.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_eip.NATGw1Eip.public_ip}"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_eip.NATGw1Eip.public_ip}"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_eip.NATGw2Eip.public_ip}"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_eip.NATGw2Eip.public_ip}"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "ProxySecurityGroup"
  }
}

resource "aws_security_group" "OuterProxySecurityGroup" {
  name        = "OuterProxySecurityGroup"
  description = "Outer Proxy Security Group"
  vpc_id     = "${aws_vpc.AdopVPC.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_security_group.ProxySecurityGroup.id}"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_security_group.ProxySecurityGroup.id}"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "OuterProxySecurityGroup"
  }
}

resource "aws_elb" "ProxyELB" {
  name               = "ProxyELB"
  availability_zones = ["${aws_subnet.PublicSubnet1.availability_zone}", "${aws_subnet.PublicSubnet2.availability_zone}"]
  security_groups = ["${aws_security_group.ELBSecurityGroup.id}", "${aws_security_group.ProxySecurityGroup.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 443
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "http" #need to modify
    #ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  idle_timeout                = 600
  cross_zone_load_balancing   = true
  idle_timeout                = 400

  tags {
    Name = "ProxyELB"
  }
}

