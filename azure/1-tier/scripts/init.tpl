#!/bin/bash

##wait for the route table us updated
sleep 30

## Getting UserData Script
curl -L https://raw.githubusercontent.com/luismsousa/adopTerraform/master/aws/1-tier/scripts/userData.sh > ~/userData.sh
chmod +x ~/userData.sh

## Set Vars
export INITIAL_ADMIN_USER=${adop_username}
export INITIAL_ADMIN_PASSWORD_PLAIN=${adop_password}


## Running UserData Script
cd ~/
./userData.sh