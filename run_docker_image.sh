#!/bin/bash
source options.sh
NAME=${1:-opensimrt_ros_}
CATKIN_WS_DIR=${2:-$(pwd)/catkin_ws}
mkdir -p $CATKIN_WS_DIR/devel
mkdir -p $CATKIN_WS_DIR/build
THIS_WINDOW_TITLE="MAIN WINDOW DO NOT CLOSE!!!! [$CATKIN_WS_DIR] $BRANCH"

echo -en "\e]0;${THIS_WINDOW_TITLE}\a"

if [ "$(uname)" == "Darwin" ]; then
	# Do something under Mac OS X platform
	# I can only run in x86_64 systems, so I should also warn the person.
	if [ "$(uname -m)" != "x86_64" ]; then
		echo "The only currently supported architecture is x86_64. You need to change the ros.Dockerfile to compile everything with this architecture ($(uname -m))."
		exit
	fi
	docker run --rm -it \
		-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \
		--name=$NAME \
		--device=/dev/dri:/dev/dri \
		$DOCKER_IMAGE_NAME
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	# Do something under GNU/Linux platform

	# I can only run in x86_64 systems, so I should also warn the person.
	if [ "$(uname -m)" != "x86_64" ]; then
		echo "The only currently supported architecture is x86_64. You need to change the ros.Dockerfile to compile everything with this architecture ($(uname -m))."
		exit
	fi
	

	if [ "$USE_ANDROID_VM" = true ]; then #bash is weird...
		#let's also run the vm for the android device
		# it doesnt seem to work if the bt dongle is already plugged in, so let's check for that
		if [[ $BT_INSERTED ]]; then
			echo "Remove BT device before starting VM..."
			exit 0
		fi
		echo "You can put the dongle after the android vm has started"
		scripts/how_to_start_bt_androidx86_vm.py &
	fi
	## slightly better alternative, it was working, but stopped, going back to open everything
	#	xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -
	xhost +local:docker

	## remembers current ssid before creating hotspot
	if [ "$USE_HOTSPOT" = true ]; then
		## I actually need to grep it by the device, right, I am assuming your wlan dev has a w in its device name, hence the grep w, but it should be a variable..
		myssid=$(nmcli -t -f name,device connection show --active | grep w | cut -d\: -f1)
		nmcli con up "${CONNECTION_NAME}"
	fi
	EXTRA_OPTIONS=""
	if [ "$IS_ROOTLESS" = true ] || [ "$USE_HOST_NETWORK" = true ]; then

		EXTRA_OPTIONS=--network=host
	else
		EXTRA_OPTIONS=-p 9000:9000/udp \
		-p 8001:8001/udp \
		-p 10000:10000/udp \
		-p 9999:9999 \
		-p 1030:1030/udp
	fi
	#not sure if I need to expose these ports, but it is working
	docker run --rm -it $EXTRA_OPTIONS \
		-e WINDOW_TITLE="${THIS_WINDOW_TITLE}" \
		-e DISPLAY=unix$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /tmp/.docker.xauth:/tmp/.docker.xauth:rw -e XAUTHORITY=/tmp/.docker.xauth \
		--name=$NAME \
		--device=/dev/snd:/dev/snd \
		--device=/dev/dri:/dev/dri $LINE \
		-v $CATKIN_WS_DIR:/catkin_ws \
		-v $(pwd)/Data:/srv/host_data \
		-v $(pwd)/tmux:/usr/local/bin/tmux_session \
		-v /run/user/${USER_UID}/pulse:/run/user/${USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER}/pulse \
		--volume /dev/bus/usb/$BUS/$PORT:/dev/bus/usb/$BUS/$PORT \
		-e PULSE_SERVER=unix:/run/user/${USER_ID_THAT_WAS_USED_TO_BUILD_THIS_DOCKER}/pulse/native \
		-e OUTSIDEY_USER_ID=${USER_UID} \
		$DOCKER_IMAGE_NAME /bin/bash -l
	if [ "$USE_HOTSPOT" = true ]; then
		nmcli con down "${CONNECTION_NAME}"
		nmcli con up $myssid
	fi


elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
	# Do something under 32 bits Windows NT platform
	docker run --rm -it \
		-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \
		--name=$NAME \
		--device=/dev/dri:/dev/dri \
		$DOCKER_IMAGE_NAME
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
	# Do something under 64 bits Windows NT platform
	winpty docker run --rm -it -p 8080:8080/udp \
		-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \
		--name=$NAME \
		$DOCKER_IMAGE_NAME


fi
echo -en "\e]0;Terminal\a"





