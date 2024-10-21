#!/bin/bash
source options.sh
NAME=${1:-opensimrt_ros_}
if [ -z "$2" ] || [ ! -d "$2" ]
  then
    log_warn "No catkin workspace argument supplied or directory $2 does not exist . Not mounting anything"

    THIS_WINDOW_TITLE="MAIN WINDOW DO NOT CLOSE!!!! $BRANCH"
else
    CATKIN_WS_DIR="$(basename $2)"

    #CATKIN_WS_DIR=${2:-$(pwd)/catkin_ws}
    if [ "$CATKIN_WS_DIR" = catkin_ws ]; then
    	CATKIN_WS_DIR=${CATKIN_WS_DIR}_2
    fi
    mkdir -p $CATKIN_WS_DIR/devel
    mkdir -p $CATKIN_WS_DIR/build
    THIS_WINDOW_TITLE="MAIN WINDOW DO NOT CLOSE!!!! [$CATKIN_WS_DIR] $BRANCH"
    ## i cant make sense of this
    #EXTRA_OPTIONS=${EXTRA_OPTIONS}" -v $2:/$CATKIN_WS_DIR "
    EXTRA_OPTIONS=${EXTRA_OPTIONS}" -v $2:/catkin_ws "
fi

##first 2 arguments need to be the name of the run instance and the catkin_ws to be mounted.
if [ -n "$1" ]; then
	log_info "shifting NAME: $1"
	shift
fi
if [ -n "$1" ]; then
	log_info "shifting CATKIN_WS_DIR: $1"
	shift
fi

## defining run command
if [ -n "$1" ]; then
	#RUN_COMMAND=$@
	RUN_COMMAND="/bin/bash -l -c /catkin_ws/prediags.bash"
	log_info running command: $RUN_COMMAND
else
	RUN_COMMAND="/bin/bash -l"
fi


echo -en "\e]0;${THIS_WINDOW_TITLE}\a"

if [ "$(uname)" == "Darwin" ]; then
	# Do something under Mac OS X platform
	# I can only run in x86_64 systems, so I should also warn the person.
	if [ "$(uname -m)" != "x86_64" ]; then
		log_warn "The only currently supported architecture is x86_64. You need to change the ros.Dockerfile to compile everything with this architecture ($(uname -m))."
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
		log_warn "The only currently supported architecture is x86_64. You need to change the ros.Dockerfile to compile everything with this architecture ($(uname -m))."
		exit
	fi
	
	log_debug $EXTRA_OPTIONS
	docker run --rm -it $EXTRA_OPTIONS \
		-e WINDOW_TITLE="${THIS_WINDOW_TITLE}" \
		--name=$NAME \
		-v $(pwd)/Data:/srv/host_data \
		-v $(pwd)/tmux:/usr/local/bin/tmux_session \
		-e OUTSIDEY_USER_ID=${USER_UID} \
		$DOCKER_IMAGE_NAME $RUN_COMMAND
	## cleanup
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





