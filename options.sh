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

USE_BROADCAST_PACKAGES=true

USE_HOTSPOT=false #false # true
CONNECTION_NAME="x-IMU3 Network(AP)"

USE_VIDEO=true #what I really mean is using X. if you want to show the opengl visuals or flexbe, you need this to be true

USE_SOUND=true # to have the wav files play correctly

USE_CAMERAS=true

USERNAME=rosopensimrt
USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER=908
USER_GID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER=908
COMPLETE_BUILD=true
SUFFIX=_complete

USE_REALSENSE=true


####SETUP

IS_ROOTLESS=false
# I think this is a linux only issue.
DOCKER_DEAMON_PROCESS_OWNER=$(ps aux | grep [d]ockerd | awk '{print $1}')

if [ "$DOCKER_DEAMON_PROCESS_OWNER" != "root" ]; then
	printf "\e[33m\n\tWARNING:\tWhen using docker rootless, the volumes don't mount properly, which means you wont be able to change data from the host while the container is running.\n\n"
	printf "\tTo save data, you need to change the volume belong to the subuser that is running inside the container.\n"
	printf "\tTo do this you need to start a \"root\" instance and use chown -R and set it to the name of the user that was used to build the container\n"

	printf "\tafter you are done with it you can just chown recursively to your own user outside the docker container.\n\n\e[0m"
	IS_ROOTLESS=true
fi

echo $IS_ROOTLESS

USER_UID=$(id -u)

EXTRA_OPTIONS=""

	if [ "$USE_ANDROID_VM" = true ]; then #bash is weird...
		#let's also run the vm for the android device
		# it doesnt seem to work if the bt dongle is already plugged in, so let's check for that
		BT_INSERTED=$(lsusb -d $BT_DONGLE_VENDOR_ID)
		if [[ $BT_INSERTED ]]; then
			echo "Remove BT device before starting VM..."
			exit 0
		fi
		echo "You can put the dongle after the android vm has started"
		scripts/how_to_start_bt_androidx86_vm.py &
	fi
	
	## remembers current ssid before creating hotspot
	if [ "$USE_HOTSPOT" = true ]; then
		## I actually need to grep it by the device, right, I am assuming your wlan dev has a w in its device name, hence the grep w, but it should be a variable..
		myssid=$(nmcli -t -f name,device connection show --active | grep w | cut -d\: -f1)
		nmcli con up "${CONNECTION_NAME}"
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"-e USE_HOTSPOT=true "
	else
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"-e USE_HOTSPOT=false "
	fi
	if [ "$IS_ROOTLESS" = true ] || [ "$USE_BROADCAST_PACKAGES" = true ]; then
		## broadcast packages are not forwarded by default by docker, so if you cannot use direct ip addressing, you will need to use network host
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--network=host "
	else
		#not sure if I need to expose these ports, but it is working
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--p 9000:9000/udp "
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--p 8001:8001/udp "
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--p 10000:10000/udp " 
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--p 9999:9999 "
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--p 1030:1030/udp " 

	fi
	if [ "$USE_VIDEO" = true ]; then
		## slightly better alternative, it was working, but stopped, going back to open everything
		#	xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -
		xhost +local:docker

		EXTRA_OPTIONS=${EXTRA_OPTIONS}"-e DISPLAY=unix$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /tmp/.docker.xauth:/tmp/.docker.xauth:rw -e XAUTHORITY=/tmp/.docker.xauth "
		## I think this is for hardware video encoding
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--device=/dev/dri:/dev/dri "
	fi
	if [ "$USE_SOUND" = true ]; then
		
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--device=/dev/snd:/dev/snd "
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"-e PULSE_SERVER=unix:/run/user/${USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER}/pulse/native "
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"-v /run/user/${USER_UID}/pulse:/run/user/${USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER}/pulse "
	fi
	if [ "$USE_REALSENSE" = true ]; then
		#IIRC this is to share the realsense camera
		BUS=$(lsusb | grep 8086 | cut -d " " -f 2)
		PORT=$(lsusb | grep 8086 | cut -d " " -f 4 | cut -d ":" -f 1)
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"--volume /dev/bus/usb/$BUS/$PORT:/dev/bus/usb/$BUS/$PORT "
	fi
	if [ "$USE_CAMERAS" = true ]; then
		FILES="/dev/video*"
		V4LDEVICES=""
		for f in $FILES
		do
			if [ -e "$f" ]; then
			#echo "Adding video device $f ..."
			# take action on each file. $f store current file name
				V4LDEVICES="--device=$f:$f $V4LDEVICES"
			fi
		done
		#echo $V4LDEVICES
		EXTRA_OPTIONS=${EXTRA_OPTIONS}"$V4LDEVICES "
	fi



BRANCH_RAW=$(git branch --show-current )

## sanitize branch name
sanitize_tag() {
    echo "$1" | sed -e 's/[^a-zA-Z0-9._-]/_/g' | tr '[:upper:]' '[:lower:]' | sed -e 's/^[-._]//g' -e 's/[-._]$//g'
}
BRANCH=$(sanitize_tag "$BRANCH_RAW")

if [[ -z "$BRANCH" ]]; then
	echo "In a detached head state, build tag will be set to latest."
	BRANCH=latest
fi
#VIDEOGROUP=$(getent group video | awk -F: '{print $3}')

#DOCKER_IMAGE_NAME=rosopensimrt/opensim-rt:devel-all
DOCKER_IMAGE_NAME=${USERNAME}/opensim-rt${SUFFIX}:$BRANCH 


