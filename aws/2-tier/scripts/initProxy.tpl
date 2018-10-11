#!/bin/bash

##wait for the route table us updated
sleep 30

## Getting UserData Script
curl -L https://raw.githubusercontent.com/luismsousa/adopTerraform/master/aws/2-tier/scripts/userDataProxy.sh > ~/userData.sh
chmod +x ~/userData.sh

## Set Vars
export InternalProxyDnsName=${adop_private_ip}

## Running UserData Script
cd ~/
./userData.sh