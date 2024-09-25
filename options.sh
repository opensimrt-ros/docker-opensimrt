#!/usr/bin/env sh

######################################################################
# @author      : frekle (frekle@bml01.mech.kth.se)
# @file        : options
# @created     : Wednesday Sep 25, 2024 15:31:49 CEST
#
# @description : 
######################################################################

#BRANCH=latest

USE_ANDROID_VM=false #true
BT_DONGLE_VENDOR_ID=0bda:8771

USERNAME=rosopensimrt
USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER=908
USER_GID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER=908
COMPLETE_BUILD=true
SUFFIX=_complete

USE_HOTSPOT=false # true
CONNECTION_NAME="x-IMU3 Network(AP)"

#IIRC this is to share the realsense camera
BUS=$(lsusb | grep 8086 | cut -d " " -f 2)
PORT=$(lsusb | grep 8086 | cut -d " " -f 4 | cut -d ":" -f 1)

USER_UID=$(id -u)

BRANCH_RAW=$(git branch --show-current )

## sanitize branch name
sanitize_tag() {
    echo "$1" | sed -e 's/[^a-zA-Z0-9._-]/_/g' | tr '[:upper:]' '[:lower:]' | sed -e 's/^[-._]//g' -e 's/[-._]$//g'
}
BRANCH=$(sanitize_tag "$BRANCH_RAW")
#VIDEOGROUP=$(getent group video | awk -F: '{print $3}')

#DOCKER_IMAGE_NAME=rosopensimrt/opensim-rt:devel-all
DOCKER_IMAGE_NAME=${USERNAME}/opensim-rt${SUFFIX}:$BRANCH 

BT_INSERTED=$(lsusb -d $BT_DONGLE_VENDOR_ID)

# I think this is a linux only issue.
# I hope this is solved
DOCKER_DEAMON_PROCESS_OWNER=$(ps aux | grep [d]ockerd | awk '{print $1}')
if [ "$DOCKER_DEAMON_PROCESS_OWNER" != "root" ]; then
	printf "\e[33m\n\tWARNING:\tWhen using docker rootless, the volumes won't mount properly, which means you wont be able to save data.\n\n"
	printf "\tTo save data, you need to make the volume belong to the subuser that is running inside the container.\n"
	printf "\tTo do this you need to start a \"root\" instance and use chown -R and set it to the name of the user that was used to build the container\n"
	printf "\tafter you are done with it you can just chown recursively to your own user outside the docker container.\n\n\e[0m"
fi


FILES="/dev/video*"
LINE=""


for f in $FILES
do
	if [ -e "$f" ]; then
	#echo "Adding video device $f ..."
	# take action on each file. $f store current file name
		LINE="--device=$f:$f $LINE"
	fi
done
echo $LINE


