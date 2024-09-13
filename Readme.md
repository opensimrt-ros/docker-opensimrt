# docker opensimrt

![Docker Build Status](https://github.com/opensimrt-ros/docker-opensimrt/actions/workflows/docker-image.yml/badge.svg?branch=main)

This repository contains scripts for building and launching OpenSimRT with a ROS interface. It was based on the [CI yaml from OpenSimRT](https://github.com/mitkof6/OpenSimRT). 

While it was meant to be used on Linux, it may be possible to use other Docker for Windows or Mac (see below).

To use it you need to have [docker installed](https://docs.docker.com/get-docker/).

Install this font [here](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Mono.otf).

## Installation:

Clone it like this:

    git clone --recursive -b main git@github.com:opensimrt-ros/docker-opensimrt

Build with :

    $ bash build_docker_image.sh

Run with:

    $ bash devel_run_docker_image.sh
    
# Structure

All of this code is a wrapper for opensim. The code was devided into 2 different workspaces to reduce compilation times so opensimrt_core can be compiled during the build script and the main catkin workspace can be compiled at runtime. This allowed us to share catkin\_ws as a docker volume and make sure that code changes are not lost between multiple sessions.

# First time usage:

After building or downloading the docker image you can run this with:

    $ bash devel_run_docker_image.sh

But the code from the catkin workspace is not yet compiled, so inside the docker run:

    $ source /catkin_ws/devel/setup.bash

And

    $ catkin_build_ws.bash

This should compile everything. If something fails, please open an issue. 

The last step is copying the python moticon_insoles sdk to catkin_devel/src/rosbiomech/insoles/moticon_insoles/src/moticon_insoles/sdk . This is paid software so I can't include it here.

# Usage: 

First source the workspace:
    
    $ source /catkin_ws/devel/setup.bash

You probably want to use flexbe to acquire data. 

    $ roslaunch acquisition_of_raw_data flexbe_all_tmux.launch

This should launch a nice tmux split screen and the flexbe interface. Load the behavior "insoles_upright" and start it. The states and the log hints will guide you through the procedure.

# Docker builds

While you still need to download this repository to run everything, you can probably just get the latest docker image

## Latest build

The latest version of the ros/docker available can be downloaded with:

    docker pull rosopensimrt/ros

Run as usual with:

    $ bash devel_run_docker_image.bash


# Using AR

Your camera needs to be calibrated and the fiducials need to be printed. More details in https://github.com/opensimrt-ros/ar_test

# XIMU port forwarding

To use XIMU3 sensors with WiFi, docker needs to be able to access the appropriate ports. Those need to be setup correctly in the "run\_docker\_image.sh" script and possibly in the ros.Dockerfile.

# Windows and Mac users

Currently the visualizations (either from rViz or from OpenSim) are using X, so to be able to see visual output you will need an X server. Docker networking with ROS can be tricky and we provide no support for those cases. If you know what you are doing, you can forward the topics to another Linux PC with ROS natively. 

## Windows Users:

To show graphics make sure you have either Xming or vcxsrv installed and running. 

Xming and vcxsrv will be running on the WSL ip address of your computer. You can check this IP by either opening a CMD (windows key + R then type cmd, in command prompt type ipconfig and use the IP from WSL) or by checking the log file from xming/ vcxsrv.

This ip will be used to set the DISPLAY variable which will run inside the docker as

    $ export DISPLAY=172.23.64.1:0.0

Or whatever your ip is. 

### Known issues

## ARM64 support

No. Maybe you can get away with compiling everything from scratch by cloning the `devel-all` branch and building that docker. 

## Slow graphics on Windows/Mac

Showing OpenSim graphics in Linux uses X forwarding with hardware acceleration. This is not available in Windows (as far as I know) and may the reason why running the Docker inside Windows has such slow performance.

## Mac Users:

The X server for MacOS is XQuartz. It may have the same limitations as Windows visualization, but this has not been tested.

