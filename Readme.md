# docker opensimrt

![Docker Build Status](https://github.com/opensimrt-ros/docker-opensimrt/actions/workflows/docker-image.yml/badge.svg?branch=main)

This repository contains scripts for building and launching OpenSimRT with a ROS interface. It was based on the [CI yaml from OpenSimRT](https://github.com/mitkof6/OpenSimRT). 

While it was meant to be used on Linux, it may be possible to use other Docker for Windows or Mac (see below).

To use it you need to have [docker installed](https://docs.docker.com/get-docker/).

## Newest instructions:

Clone it like this to get everything:

    git clone --recursive -b devel-all git@github.com:opensimrt-ros/docker-opensimrt opensimrt


#### Everything below here is old. needs to be reviewed and updated.


Build with :

    $ bash build_docker_image.sh

Run with:

    $ bash run_docker_image.sh
    
Note: currently the PS1 is set to look pretty (it can be confusing to know whether you are inside the docker instance or main machine). For that to work you need to install a Nerd font and set your terminal to use it. The font we use is DroidSansMono Nerd Font Mono, available [here](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Mono.otf).

# Structure

The code was devided into 2 different workspaces to reduce compilation times so opensimrt_core can be compiled during the build script and the main catkin workspace can be compiled at runtime. This allowed us to share catkin\_ws as a docker volume and make sure that code changes are not lost between multiple sessions.

# First time use:

We are now using a big repo with everything for the ease of it. 

create a directory called 

    mkdir -p catkin_devel/src

do a 

    git clone git@gits-15.sys.kth.se:frekle/ros_biomech.git

then do:

    git submodule update --init --recursive

## Troubleshooting:
	
I've done some shady things with the submodules here, so you might need to change .gitmodules and the .git/config file to put the correct reference for the tmux_session module. This was an old idea and it is quite complicated, so it will be phased out at some point (if I have time), but right now it is necessary. 


Run the docker image loader script: 

    $ bash run_docker_image.sh

Inside the docker run the script:

    $ first_time_catkin_builder.sh

You should be set to move to Usage.

## Manually getting the appropriate packages:

In case you don't want to download everything, you can instead create your catkin workspace yourself.

Run the docker image loader script: 

    $ bash run_docker_image.sh

Navigate to the directory ´/catkin_ws/src´ and get the appropriate repositories:

    $ git clone https://github.com/opensimrt-ros/osrt_ros.git -b devel
    $ git clone https://github.com/opensimrt-ros/opensimrt_msgs.git
    $ git clone https://github.com/opensimrt-ros/gait1992_description.git
    
If you want to use ALVAR:

    $ git clone https://github.com/machinekoder/ar_track_alvar.git -b noetic-devel
    $ git clone https://github.com/opensimrt-ros/ar_test -b fixing_cube
    
If you want to use a webcam as video input:

    $ git clone https://github.com/ros-drivers/usb_cam.git
   
If you want XIMU3 drivers:

    $ git clone https://github.com/opensimrt-ros/ximu3_ros.git

After getting all the relevant packages, you need to use the script to compile the workspace (it set's up some environment variables needed by opensimrt\_core and osrt\_ros):

    $ catkin_build_ws.bash 

# Usage: 

The demos are tmux sessions which load roscore and the necessary roslaunch files. Tmux was used to allow for easier debug. Neovim is also available for editing source code with YouCompleteMe installed for code completion. 

First source the workspace:
    
    $ source /catkin_ws/devel/setup.bash
    
And execute the launcher script:

    $ rosrun osrt_ros tmux_session_XXX
    
Where XXX is the particular demo. Use tab completion to list all available options.

## Existing examples:

- `tmux_session_ar.bash` Test ALVAR marker cube

- `tmux_session_test_agrf.bash` Test acceleration based state-machine GRFM predictions  

- `tmux_session_test_cgrf.bash` Test contact force based state-machine GRFM predictions

- `tmux_session_test_gait1992_visuals.bash` Test URDF model

- `tmux_session_test_id_agrf.bash` Test ID and acceleration based GRFM pipeline*

- `tmux_session_test_id_cgrf.bash` Test ID and contact-force based GRFM pipeline*

- `tmux_session_test_id_combined_agrf.bash` Test ID+SO and acceleration based GRFM pipeline*,**

- `tmux_session_test_id_combined_cgrf.bash` Test ID+SO and contact-force based GRFM pipeline*,**

- `tmux_session_test_single_ar_with_lowerbody.bash` Test ALVAR marker cube single input with static transforms to pelvis, lowerbody, only IK

- `tmux_session_test_single_ar_with_upperbody.bash` Test ALVAR marker cube single input with static transforms to pelvis, upperbody, only IK

- `tmux_session_test_single_ximu_with_lowerbody.bash` Test XIMU3 single input with static transforms to pelvis, lowerbody, only IK

- `tmux_session_test_single_ximu_with_upperbody.bash` Test XIMU3 single input with static transforms to pelvis, upperbody, only IK

\* Note here the filtering is still happening inside the node, so there is additional 35 samples wait until there are enough values for visualization

\*\* Here the speed of the playback is reduced to 33fps as the algorithm cannot run faster on our machine. Your machine likely has different specs, so change the rate\_divider accordingly to be able to reach convergence for every frame.

# Docker builds

## Latest build

The latest version of the ros/docker available can be downloaded with:

    docker pull rosopensimrt/ros

To run the docker you just downloaded you need X forwarding to work, so 

    xhost +
    
Under linux it can then be run with:

	docker run --rm -it \
		-p 9000:9000/udp \
		-p 8001:8001/udp \
		-p 10000:10000/udp \
		-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \
		--name=opensimrt_ros \
		--device=/dev/dri:/dev/dri \
		--device=/dev/video0:/dev/video0 \
		-v $(pwd)/catkin_ws:/catkin_ws \
		-v $(pwd)/tmux:/usr/local/bin/tmux_session\
		rosopensimrt/ros:latest /bin/bash

## Older builds

If instead you just want to use the older already built docker images, you can get them [here](https://hub.docker.com/r/mysablehats/opensim-rt/tags). We are not freezing versions, so it is possible that the builder script will break in the future. 

The docker with the default version from mitkof6/OpenSIMRT can be obtained with: 

     docker pull mysablehats/opensim-rt:main

It can also be directly accessed [here](https://hub.docker.com/layers/mysablehats/opensim-rt/main/images/sha256-f3f238759e736f2fd01b9a1eec307b9dbe664f97206e438541bb2685b9fcb38e).

# Using AR

Your camera needs to be calibrated and the fiducials need to be printed. More details in https://github.com/opensimrt-ros/ar_test

# XIMU port forwarding

To use XIMU3 sensors with WiFi, docker needs to be able to access the appropriate ports. Those need to be setup correctly in the "run\_docker\_image.sh" script and possibly in the ros.Dockerfile.

# Windows and Mac users

Currently the visualizations (either from rViz or from OpenSim) are using X, so to be able to see visual output you will need an X server. Docker networking with ROS can be tricky and we provide no support for those cases. If you know what you are doing, you can forward the topics to another Linux PC with ROS natively installed or even do your own visualization using the ROS implementation under the hood (say with an additional node serving as a tunnel). 

## Windows Users:

To show graphics make sure you have either Xming or vcxsrv installed and running. 

Xming and vcxsrv will be running on the WSL ip address of your computer. You can check this IP by either opening a CMD (windows key + R then type cmd, in command prompt type ipconfig and use the IP from WSL) or by checking the log file from xming/ vcxsrv.

This ip will be used to set the DISPLAY variable which will run inside the docker as

    $ export DISPLAY=172.23.64.1:0.0

Or whatever your ip is. 

### Known issues

Showing OpenSim graphics in Linux uses X forwarding with hardware acceleration. This is not available in Windows (as far as I know) and may the reason why running the Docker inside Windows has such slow performance.

## Mac Users:

The X server for MacOS is XQuartz. It may have the same limitations as Windows visualization, but this has not been tested.

