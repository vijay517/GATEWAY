#!/bin/bash

# exit when any command fails
set -e

#setting the path of the root directory
ROOTDIR=~/Desktop/GATEWAY

#-----------------------------------------------------------------------------------------------
#		                     PRE-REQUSITE - CHECKING IF THE gatewayinfo.txt FILE EXIST
#-------------------------------------------------------------------------------------------------

#Checking if the device info text in present
if [ ! -f $ROOTDIR/gatewayinfo.txt ]
then
        echo "gatewayinfo.txt file is not present in the directory: ${ROOTDIR}"
        exit -1
fi

#-----------------------------------------------------------------------------------------------------
#                          STEP 1 : CREATING IOT Core, CERTIFICATES, KEYS ATTACH POLICIES
#-----------------------------------------------------------------------------------------------------

#Creating a IoT thing in IoT core in aws
GREENGRASS_CORE_NAME=$(cat $ROOTDIR/gatewayinfo.txt | grep -m1 -B1 "GREENGRASS_CORE_NAME" | grep -Po 'GREENGRASS_CORE_NAME:\K.*')
aws iot create-thing --thing-name $GREENGRASS_CORE_NAME

#Create certificate and keys. After creating the keys, the certificate arn is stored for further use
certificateArn=$(aws iot create-keys-and-certificate --set-as-active --certificate-pem-outfile certificate.pem.crt --private-key-outfile private.pem.key | grep -B1 certificateArn | grep -Po '"'"certificateArn"'"\s*:\s*"\K([^"]*)')

#Move the private key and certificate to the certificate directory
mv private.pem.key certificate.pem.crt $ROOTDIR/certificates

#Attach the policy to certificate and certificate to the thing
GREENGRASS_CORE_POLICY_NAME=$(cat $ROOTDIR/gatewayinfo.txt | grep -m1 -B1 "GREENGRASS_CORE_POLICY_NAME" | grep -Po 'GREENGRASS_CORE_POLICY_NAME:\K.*')
aws iot attach-policy --policy-name $GREENGRASS_CORE_POLICY_NAME --target $certificateArn
aws iot attach-thing-principal --thing-name $GREENGRASS_CORE_NAME --principal $certificateArn

#Create Core definition
CORE_ARN=$(aws iot describe-thing --thing-name $GREENGRASS_CORE_NAME | grep -B1 thingArn | grep -Po '"'"thingArn"'"\s*:\s*"\K([^"]*)')
DEFINITION="{\"Cores\":[{\"Id\":\"${GREENGRASS_CORE_NAME}\",\"ThingArn\":\"${CORE_ARN}\",\"CertificateArn\":\"${certificateArn}\",\"SyncShadow\":true}]}"
DEFINITION_ARN=$(aws greengrass create-core-definition --name "${GREENGRASS_CORE_NAME}-DEFINITION" --initial-version $DEFINITION | grep -B1 LatestVersionArn | grep -Po '"'"LatestVersionArn"'"\s*:\s*"\K([^"]*)')

#-----------------------------------------------------------------------------------------------------
#                               STEP 2 : CREATING GREENGRASS GROUP
#-----------------------------------------------------------------------------------------------------

#Create Greengrass group
GROUP_NAME=$(cat $ROOTDIR/gatewayinfo.txt | grep -m1 -B1 "GROUP_NAME" | grep -Po 'GROUP_NAME:\K.*')
GROUPID=$(aws greengrass create-group --name $GROUP_NAME --initial-version "{\"CoreDefinitionVersionArn\": \"${DEFINITION_ARN}\"}" | grep -B1 Id | grep -Po '"'"Id"'"\s*:\s*"\K([^"]*)')
sed -i -E "s/GROUP_ID:(.*)/GROUP_ID:${GROUPID}/" $ROOTDIR/gatewayinfo.txt

echo "GROUP CREATED"