#!/bin/bash
## Getting UserData Script
curl -L https://raw.githubusercontent.com/luismsousa/adopTerraform/master/aws/1-tier/scripts/userData.sh > ~/userData.sh
chmod +x ~/userData.sh

## Set Vars
export INITIAL_ADMIN_USER=${adop_username}
export INITIAL_ADMIN_PASSWORD_PLAIN=${adop_password}
export INITIAL_ADMIN_PASSWORD_PLAIN=${adop_password}
export SecretS3BucketStore=${s3_bucket_name}
export KeyName=${key_name}

## Running UserData Script
cd ~/
./userData.sh