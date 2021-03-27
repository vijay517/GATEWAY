#!/bin/bash

ROOTDIR=~/Desktop/GATEWAY

#-----------------------------------------------------------------------------------------------------
#       STEP 1 : ADDING ggc_user and ggc_group to gateway under which the Lambda function will run
#-----------------------------------------------------------------------------------------------------
#Note do not run this step if there are users already
sudo adduser --system ggc_user
sudo groupadd --system ggc_group

# exit when any command fails
set -e

#-----------------------------------------------------------------------------------------------------------
#     STEP 2 : GREENGRASS REQUIRES THAT THE SECURITY IS IMPROVED BY ENABLING HARDLINK AND SOFTLINK PROTECTION
#-----------------------------------------------------------------------------------------------------------
n=$(grep 'fs.protected_hardlinks = 1' /etc/sysctl.d/00-defaults.conf | wc -l)
if (($n == 0)); then echo 'fs.protected_hardlinks = 1' | sudo tee -a /etc/sysctl.d/00-defaults.conf; fi

n=$(grep 'fs.protected_symlinks = 1' /etc/sysctl.d/00-defaults.conf | wc -l)
if (($n == 0)); then echo 'fs.protected_symlinks = 1' | sudo tee -a /etc/sysctl.d/00-defaults.conf; fi
sudo sysctl --system

#-----------------------------------------------------------------------------------------------------
#    		 STEP 3 : RUN THE FOLLOWING SCRIPT TO MOUNT LINUX CONTROL GROUPS (cgroups)
#-----------------------------------------------------------------------------------------------------
cd /tmp
curl https://raw.githubusercontent.com/tianon/cgroupfs-mount/951c38ee8d802330454bdede20d85ec1c0f8d312/cgroupfs-mount >cgroupfs-mount.sh
chmod +x cgroupfs-mount.sh
sudo bash ./cgroupfs-mount.sh
echo ""
#-----------------------------------------------------------------------------------------------------
#     				STEP 4 : INSTALLING GREEN GRASS SOFTWARE
#-----------------------------------------------------------------------------------------------------

cd /tmp

if [ ! -f "/tmp/greengrass-linux-$(uname -m)-1.10.2.tar.gz" ]; then
	sudo wget "https://d1onfpft10uf5o.cloudfront.net/greengrass-core/downloads/1.10.2/greengrass-linux-$(uname -m)-1.10.2.tar.gz"
	sudo tar -xzf "greengrass-linux-$(uname -m)-1.10.2.tar.gz" -C /
	echo ""
	sudo sed -i -E "s/CONFIGURED_FILE:Yes/CONFIGURED_FILE:No/" $ROOTDIR/gatewayinfo.txt
fi

#-----------------------------------------------------------------------------------------------------
#     				STEP 5 : CREATING GREENGRASS GROUP
#-----------------------------------------------------------------------------------------------------

#Creating a greengrass group if not found
GROUP_ID=$(cat $ROOTDIR/gatewayinfo.txt | grep -m1 -B1 "GROUP_ID" | grep -Po 'GROUP_ID:\K.*')
OUTPUT=$(aws greengrass get-group --group-id $GROUP_ID)

if [ -z $OUTPUT ]; then
	$ROOTDIR/executable_files/setup_greengrass_group_core.sh
else
	echo "GROUP FOUND"
fi

#Check configuration status
CONFIG_STATUS=$(cat ~/Desktop/GATEWAY/gatewayinfo.txt | grep -m1 -B1 "CONFIGURED_FILE" | grep -Po 'CONFIGURED_FILE:\K.*')

if [ $CONFIG_STATUS == "No" ]; then
	echo "Staus config is No"
	#Configure the green grass configuration json file
	$ROOTDIR/executable_files/setup_greengrass_config_file.sh

	#Place the AWS IoT Root Certificate Authority in the /greengrass/certs folder
	cd /greengrass/certs/
	sudo wget -O root.ca.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
	cd $ROOTDIR/certificates
	sudo wget -O root.ca.pem https://www.websecurity.digicert.com/content/dam/websitesecurity/digitalassets/desktop/pdfs/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem
	#Replacing the configuration status in the gatewayinfo.txt file
	sudo sed -i -E "s/CONFIGURED_FILE:No/CONFIGURED_FILE:Yes/" $ROOTDIR/gatewayinfo.txt
else
	echo "Staus config is Yes"
fi

#Start greengrass core software
$ROOTDIR/executable_files/display_msg.sh "STATUS OF GREENGRASS CORE"
cd /greengrass/ggc/core/
GREENGRASS_CORE_STATUS=$(sudo ./greengrassd start)
echo $GREENGRASS_CORE_STATUS

#Running the anomaly detection script if the code is GREEGRASS CORE is sucessfully started
$ROOTDIR/executable_files/display_msg.sh "ANOMALY DETECTION SCRIPT"
if [[ "$GREENGRASS_CORE_STATUS" =~ "Greengrass successfully started with PID" ]]; then
	cd ~/nupic/examples/opf/clients/hotgym/anomaly/one_gym
	python run.py 
else
	echo "ANOMALY DETECTION SCRIPT IS NOT EXECUTED AS THE GREENGRASS SOFTWARE IS NOT RUNNING "
fi