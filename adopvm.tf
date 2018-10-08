resource "aws_instance" "Adop" {
  ami = "${var.ami_id}"
  instance_type = "m4.xlarge"
  vpc_security_group_ids = ["${aws_security_group.ADOPSecurityGroup.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = "false"
  } 

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp2"
    volume_size = "15"
    delete_on_termination = "false"
  }

  ebs_block_device {
    device_name = "/dev/sdg"
    volume_type = "gp2"
    volume_size = "25"
    delete_on_termination = "false"
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_type = "gp2"
    volume_size = "25"
    delete_on_termination = "false"
  }

  user_data = <<-EOF
  #!/bin/bash
  ## Getting UserData Script
  curl -L https://raw.githubusercontent.com/luismsousa/adopTerraform/master/scripts/userData.sh > ~/userData.sh
  chmod +x ~/userData.sh
  ## Running UserData Script
  cd ~/
  ./userData.sh
  EOF

  tags{
      Name = "Adop"
  }
}


