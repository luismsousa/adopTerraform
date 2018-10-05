resource "aws_network_interface" "adopni" {
  subnet_id = "${aws_subnet.my_subnet.id}"
  private_ips = ["172.16.10.100"]
  tags {
    Name = "luisAdopNetworkInterface"
  }
}

resource "aws_instance" "foo" {
  ami = "ami-22b9a343" # us-west-2
  instance_type = "t2.micro"
  network_interface {
    network_interface_id = "${aws_network_interface.foo.id}"
    device_index = 0
  }
  credit_specification {
    cpu_credits = "unlimited"
  }
}
