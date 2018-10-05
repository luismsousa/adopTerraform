provider "aws" {
  region                  = "eu-west-1"
  #shared_credentials_file = "/Users/luis.m.sousa/.aws/creds"
  #profile                 = "terraform_workshop"
  access_key = "${aws_access_key}"
  secret_key = "${aws_secret_key}"
}