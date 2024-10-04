#!/usr/bin/env bash
set -e

source /opt/ros/$ROS_DISTRO/setup.bash
#get_latest_local_branches.bash
#catkin_build_ws.bash
export PATH=/usr/local/bin/tmux_session:$PATH
export OPENSIMRTDIR=opensimrt_core

## check if XDG_RUNTIME_DIR exists and it is writable

if [[ -d "$XDG_RUNTIME_DIR" && -w "$XDG_RUNTIME_DIR" ]]; then
	echo "ok"
else
	#export XDG_RUNTIME_DIR=/tmp/`whoami`
	export XDG_RUNTIME_DIR=/var/run/dbus
	#mkdir -p $XDG_RUNTIME_DIR
fi

## I should get this from options//
DOCKER_USER_NAME=rosopensimrt

## if we want screen, sound and dev, this is unavoidable.
# maybe when they fix the way volumes are mounted this can all be removed
echo "Changing userid. This takes a long time..."
usermod -u ${OUTSIDEY_USER_ID} $DOCKER_USER_NAME
groupmod -g ${OUTSIDEY_USER_ID} $DOCKER_USER_NAME

export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR
gosu $OUTSIDEY_USER_ID dbus-daemon --session --address=$DBUS_SESSION_BUS_ADDRESS --nofork --nopidfile --syslog-only &
#dbus-daemon --session --address=$DBUS_SESSION_BUS_ADDRESS --nofork --nopidfile --syslog-only &

## This doesn't work. I mean, it works, but not completely.

# inspired by: https://github.com/redis/docker-library-redis/blob/master/Dockerfile.template& https://github.com/redis/docker-library-redis/blob/master/docker-entrypoint.sh


ACTUAL_USER_ID=$OUTSIDEY_USER_ID
if [ "$IS_ROOTLESS" = "true" ]; then
	OUTSIDEY_USER_ID=root
fi

## this will maybe prevent apps outside to work :(
dirs_to_share=(
"/srv/host_data"
"/catkin_ws"
"/tmp/.X11-unix"
)
#"/dev/snd"
#"/dev/dri"

cleanup()
{
	echo "attempting cleanup"
	for some_dir in ${dirs_to_share[@]}; do
		chown -R $OUTSIDEY_USER_ID:$OUTSIDEY_USER_ID $some_dir
	done
	echo "permissions reset to $ACTUAL_USER_ID! "
}

trap "cleanup" INT EXIT

chown -R $DOCKER_USER_NAME:$DOCKER_USER_NAME /srv/host_data
chown -R $DOCKER_USER_NAME:$DOCKER_USER_NAME /catkin_ws

## Running passed command
if [[ "$1" ]]; then
	gosu $DOCKER_USER_NAME "$@"
fi


