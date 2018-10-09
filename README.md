# ADOP Terraform

## Description
This is a project to migrate [ADOP](https://github.com/Accenture/adop-docker-compose) from CloudFormation to Terraform. 

### Usage Notes
Currently testing is happening using Terraform Enterprise (TFE) Trial, will look to setting up a Github pipeline in the future.
All Empty Vars are defined in TFE Vars.

### Assumptions
* You're using AWS :)
    * You're working in Ireland Region
* You're not a neat code freak :)
* Arrays start at 0
* You're not using this for prod
* You're fine with a publicly facing EC2 Instance for now.
* Vars you need to replace are empty
* You don't have a pre-existing bucket to drop the temp creds file in.

## TODO
* add AMI Map
* ~~add user-data repo~~
    * ~~having issues with big init script~~
* ~~add VPC level network~~
    * ~~add EIP~~
* add 2 tiered-network and move ADOP to a private Subnet
* add Azure
* add GCP
* clean Folder Structure
    * done-ish