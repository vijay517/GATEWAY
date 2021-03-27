#!/bin/bash

#exit when any command fails

ROOTDIR=~/Desktop/GATEWAY

#-----------------------------------------------------------------------------------------------
#		     PRE-REQUSITE - CHECKING IF THE gatewayinfo.txt FILE EXIST
#-------------------------------------------------------------------------------------------------

#Checking if the device info text in present
if [ ! -f $ROOTDIR/gatewayinfo.txt ]; then
        echo "gateway.txt file is not present in the directory: ${ROOTDIR}"
        exit -1
fi

#------------------------------------------------------------------------------------------------------
#                                STEP 1 - Configure config file for greengrass software
#-------------------------------------------------------------------------------------------------------

#changing caPath
sudo sed -i -E "s/\[ROOT_CA_PEM_HERE\]/root.ca.pem/" /greengrass/config/config.json

#changing certPath
sudo sed -i -E "s/\[CLOUD_PEM_CRT_HERE\]/certificate.pem.crt/" /greengrass/config/config.json

#changing keyPath
sudo sed -i -E "s/\[CLOUD_PEM_KEY_HERE\]/private.pem.key/" /greengrass/config/config.json

#changing thingArn
GREENGRASS_CORE_NAME=$(cat $ROOTDIR/gatewayinfo.txt | grep -m1 -B1 "GREENGRASS_CORE_NAME" | grep -Po 'GREENGRASS_CORE_NAME:\K.*')
VALUE=$(aws iot describe-thing --thing-name $GREENGRASS_CORE_NAME | grep -B1 thingArn | grep -Po '"'"thingArn"'"\s*:\s*"\K([^"]*)')
sudo sed -i -E "s+\[THING_ARN_HERE\]+${VALUE}+" /greengrass/config/config.json

#changing iotHost
VALUE=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS | grep -Po '"'"endpointAddress"'"\s*:\s*"\K([^"]*)' | cut -d '-' -f1)
sudo sed -i -E "s/\[HOST_PREFIX_HERE\]/${VALUE}/" /greengrass/config/config.json

#changing ggHost
VALUE=$(aws configure get region)
sudo sed -i -E "s/\[AWS_REGION_HERE\]/${VALUE}/" /greengrass/config/config.json

#changing useSystemd
sudo sed -i -E "s/\[yes\|no\]/yes/" /greengrass/config/config.json

#Change file path
sudo sed -i -E "s+file://+file:///greengrass/+" /greengrass/config/config.json

#------------------------------------------------------------------------------------------------------
#                                STEP 2 - Configure config file for greengrass software
#-------------------------------------------------------------------------------------------------------

if [ ! -f $ROOTDIR/certificates/certificate.pem.crt ]; then
        echo "certificate.pem.crt file is not present in the directory: ${ROOTDIR}/certificates"
        exit -1
fi

if [ ! -f $ROOTDIR/certificates/private.pem.key ]; then
        echo "private.pem.key file is not present in the directory: ${ROOTDIR}/certificates"
        exit -1
fi

#Moving the certificates generated to the greengrass certs directory
sudo cp $ROOTDIR/certificates/{private.pem.key,certificate.pem.crt} /greengrass/certs/
