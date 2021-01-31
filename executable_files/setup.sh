#!/bin/bash

# exit when any command fails
set -e

#Setting date and time
date=$(curl -I 'https://google.com/' 2>/dev/null | grep -i '^date:' | sed 's/^[Dd]ate: //g')
echo "Setting the date and time as"
sudo date -s "${date}"

#Setup aws cli on this edge device
echo "Running setup_awscli bash script"
./setup_awscli.sh

#Setup greengrass on this edge device
echo "Running setup_greengrass bash script"
./setup_greengrass.sh