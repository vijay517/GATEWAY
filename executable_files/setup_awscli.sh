#!/bin/bash

# exit when any command fails
set -e

#setting the path of the root directory
ROOTDIR=~/Desktop/GATEWAY

#-----------------------------------------------------------------------------------------------------
#                               STEP 1 : INSTALLING AWS CLI
#-----------------------------------------------------------------------------------------------------

#Checking if the AWS CLI is installed. If it is not installed the result variable will hold a value of 0
result=$(command -v aws | wc -c)

#If the AWS CLI is not installed, then the AWS CLI V2 is installed.
if [ $result -eq 0 ]
then
        echo "The AWS CLI is not installed."
        curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
        unzip awscli-bundle.zip
        sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
        rm -r awscli-bundle.zip awscli-bundle
fi

#-----------------------------------------------------------------------------------------------------
#                       STEP 2: CHECKING IF keys.csv FILE IS  PRESENT
#-----------------------------------------------------------------------------------------------------

#Checking if the csv files containing the authentication keys exist.
if [ ! -f $ROOTDIR/certificates/keys.csv ]
then
        echo "authentication file keys.csv does not exist in the directory:" $(pwd)
        exit -1
fi

#-----------------------------------------------------------------------------------------------------
#               STEP 3: CONFIGURING AWS CLI REGION, ACCESS KEY AND SECERET KEY.
#-----------------------------------------------------------------------------------------------------

#Setting the aws region to us-east-2
aws configure set region us-east-2

#Setting the aws access key
ACCESS_KEY=$(sed -n '2p' $ROOTDIR/certificates/keys.csv | cut -d',' -f1)
aws configure set aws_access_key_id $ACCESS_KEY

#Setting the aws secret key
SECRET_KEY=$(sed -n '2p' $ROOTDIR/certificates/keys.csv | cut -d',' -f2)
aws configure set aws_secret_access_key  $SECRET_KEY

