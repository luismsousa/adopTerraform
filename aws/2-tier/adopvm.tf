resource "aws_key_pair" "ADOPKey" {
  key_name   = "terraformADOPKey"
  public_key = "${var.public_key}"
}

data "template_file" "ADOPInit" {
  template = "${file("${path.module}/scripts/init.tpl")}"

  vars {
    adop_username = "${var.adop_username}"
    adop_password = "${var.adop_password}"
    s3_bucket_name = "${aws_s3_bucket.temp_adop_credentials.id}"
    key_name = "${aws_key_pair.ADOPKey.id}"
  }
}

resource "aws_instance" "ADOPInstance" {
  ami = "${var.ami_id}"
  instance_type = "m4.xlarge"
  vpc_security_group_ids = ["${aws_security_group.ADOPSecurityGroup.id}"]
  subnet_id = "${aws_subnet.PrivateSubnet1.id}"
  key_name = "terraformADOPKey"
  user_data = "${data.template_file.ADOPInit.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.S3UploadRoleProfile.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "8" # size this up if running more than a POC
    delete_on_termination = true
  } 

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp2"
    volume_size = "15" # size this up if running more than a POC
    delete_on_termination = true
  }

  ebs_block_device {
    device_name = "/dev/sdg"
    volume_type = "gp2"
    volume_size = "25" # size this up if running more than a POC
    delete_on_termination = true
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_type = "gp2"
    volume_size = "25" # size this up if running more than a POC
    delete_on_termination = "true"
  }

  tags{
      Name = "Adop"
  }

  depends_on = ["aws_route_table_association.privateRTAssociation"]
}


