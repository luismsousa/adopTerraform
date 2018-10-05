provider "aws" {
  region                  = "eu-west-1"
  #shared_credentials_file = "/Users/luis.m.sousa/.aws/creds"
  #profile                 = "terraform_workshop"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}