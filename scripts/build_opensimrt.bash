#!/usr/bin/env bash
set -e
cd /catkin_opensim
. /etc/profile.d/opensim_envs.sh

#source src/$OPENSIMRTDIR/env.sh 
. /opt/ros/noetic/setup.sh
catkin_make -j`nproc` \
            -DCMAKE_BUILD_TYPE=Release \
            -DCONTINUOUS_INTEGRATION=OFF \
            -DBUILD_TESTING=ON \
            -DBUILD_DOCUMENTATION=OFF \
            -DDOXYGEN_USE_MATHJAX=OFF \
            -DBUILD_MOMENT_ARM=ON \
            -DBUILD_IMU=OFF \
            -DBUILD_UIMU=ON \
            -DBUILD_VICON=OFF \
	    "$@"
