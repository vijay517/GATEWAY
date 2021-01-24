#!/bin/bash

# exit when any command fails
set -e

#Setup aws cli on this edge device
./setup_awscli.sh

#Setup greengrass on this edge device
./setup_greengrass.sh