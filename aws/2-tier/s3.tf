resource "aws_s3_bucket" "temp_adop_credentials" {
  acl    = "private"
  force_destroy = true
}