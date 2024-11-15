# docker opensimrt

![Docker Build Status](https://github.com/opensimrt-ros/docker-opensimrt/actions/workflows/docker-image.yml/badge.svg?branch=feature/newest_opensim)

This repository contains scripts for building and launching OpenSimRT with a ROS interface. It was initially based on the [CI yaml from OpenSimRT](https://github.com/mitkof6/OpenSimRT), but now we are building opensim (4.5.1 at the time this was written) from source. You might want to adapt the components and their versions to your own preferences

While it was meant to be used on Linux, it may be possible to use other Docker for Windows or Mac (see below). Also this is building for x86\_64, it may work for arm64 with some changes to the dockerfiles (by using the "FROM --platform=$TARGETPLATFORM <docker-image>"), but i don't have an arm system to test it and i am not going to setup a qemu or a crosscompilation system before there is a strong need for it (to make this run on an android device you would need to install a linux kernel on your phone/tablet to run docker and this is not something most people would be okay doing, so i see little use cases now).

To use it you need to have [docker installed](https://docs.docker.com/get-docker/). Please either install docker in a rootfull way or the volume mounts won't work by default (it is easy to change the permissions of the folders with the root\_instance.sh script).

## Newest instructions:

Clone it like this to get everything:

    git clone --recursive -b devel-all https://github.com/opensimrt-ros/docker-opensimrt.git opensimrt

Then build it:

    cd opensimrt
    bash build_docker_image.sh

It will take quite a while (~2 hours with my pc). 

### Troubleshooting build:

In some computers compiling one or more components may fail. It is most likely to occur when compiling opensim, opensimrt or the rosbiomech mega package. 

If that happens, you may [want to increase your swap file (see this link on how to do this)](https://arcolinux.com/how-to-increase-the-size-of-your-swapfile/). You should aim for around 3-4GB per core (why does it use so much memory? idk. [Maybe this is related?](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=44563)). Another option is to reduce the number of processes that are running when doing make.

You can change every occurrence of "´nproc´" to something like 12 or 1 if you want to be on the safe side, like:

    make -j`nproc`

you do

    make -j1

This will use only one process, so it will take longer. But since you should only do this once, maybe that's what you want. 

## Devices:

Currently tested are only the XIMU3 imu sensors and the Moticon Insoles. The network is simple with every IMU connected to a router and an android device (also connected via wifi to the router) which runs the Moticon app as an intermediate hop between the bluetooth insoles and the router. The data exchange is done with a python script that is an addon component which can be bought from Moticon. This may be the reason for the strange lags we have from the insole data and ideally we would want to make this more streamlined. I tested having a virtual machine and linking the tablet via USB to the pc, but both of those didn't seem to make much of a difference. Maybe my android device is slow. I will publish more data once I measure this more accurately and if I find out what is the best way I will make the appropriate changes. Currently, sometimes the insoles can get up to 7s delays and then normalize. I don't know how to solve it. Likely we want a proper bluetooth linux driver here. 

You may also want to add some delay to the TF reader (maybe like 10-20ms) in IK and physically calibrate the imus with the crosscorrelation algorithm (imu\_delay\_finder package), but i haven't done it, so there might be some bugs there. The IMUs run with stable 2-30ms delays and this is okay for the types of movements we are currently measuring. For faster things, this may be necessary. 

Another improvement that can be done to the network is setting up the linux pc as an AP so you have one less hop in the network. This works just fine, but in my pc, it can deal with only a small number of hosts (wifi card issue?), but it is enough to run the 8 IMUs and the Android device we use for the insoles, but nothing else. 

### How to setup the devices:

- IMUs

If you want to use the exact same setup I used, you need to change the IPs on the Ximu3s to static ips with the right numbering and also the ports. I don't remember what exactly they are, look into the ximu3 launch files to make sure. Also the whole thing with incoming and outgoing ports is confusing to me, so if they have different IPs, the port can be the same, that probably makes somethings easier, but I didn't do that, i just set different ports for everything so I don't need to think. 

- Insoles

The insoles need to be able to contact the linux pc which will be listening on port 9999 (by default). So in the Moticon App you need to specify the IP for the linux host it's the network valid one for your wifi/ethernet adapter (docker will make a bunch of networking stuff (for virtual interfaces and bridges and so on and this will depend on your setup),  so it will look messy, and you need to know if you are using a wire or the wifi adapter ). do "hostname -I" or if you are getting confused look into "ifconfig" or the network manager/settings pane if you like guis. 

You need not only the OpenGo insoles but also **you need the buy the python SDK from Moticon as well** . To use our code as is, you need to buy this and the insoles, however, if you look at the free code provided in the moticon\_insole package, you will see that we only require a sensor that provides total force, COP posistions and a timestamp. If you can make another force sensor that provides this information, then if should be straightforward to replace the moticon sdk for something else. The SDK itself is a simple python thing reading protobuf messages that are transmitted over TCP. Note that if you are making a real-time insole device, please consider using UDP instead, since old force information is useless for a real-time platform, but lag is really difficult to deal with. 

Once you have this SDK, you need to copy it to the src/moticon\_insoles/sdk directory of the moticon\_insoles ros package (inside the catkin workspace). I think I wrote on the readme of that package how to do this. Btw, this package is not complete yet. The TFs are incorrect for the insoles IMU driver and it currently will stop you from being able to use this IMU as an orientation source for IK. It is probably not to hard to fix, but changing this will break the current ID code and the URDF gait1992 model that was set to use these "incorrect" TFs. The insoles are also not rotating the way they should (they are mirrored for some reason), so I also need to figure out why that is. If you want to fix this, be my guest. 

### Running things:

You probably want to start the acquisition state machine from flexbe. There is a bunch of signals that need to happen for things to be initialized properly and I couldn't find an easier way yet to do this, hence this state machine. 

Currently I am using the acquire\_everything behavior, but this is bound to change as well. 

The easiest way to go about it is:

After building the docker successfully either run:


#### Option 1: The intended way

    ./pre_setup_run.sh

This will run a bunch of checks to see if you have the network set properly, the android device is on, that the external camera is plugged in and your vicon system is connected to your router. 

Now, if you are not in my old lab (KTH), you are bound to have different things connected in different places, so this won't work. The file that describes this thing is in `catkin_devel/src/ros_biomech/diagnostics_schema/src/diagnostics_schema/pre_setup_diags_node.py`. I don't know how to make this general, but you can adjust this to your setup, I mean it is just a python script. 

Note: currently the for PS1 is set to look pretty (it can be confusing to know whether you are inside the docker instance or main machine) and for neovim and this script, you need to install a Nerd font and set your terminal to use it. The font we use is DroidSansMono Nerd Font Mono, available [here](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Mono.otf).

In another terminal, in the same directory run:

    ./start_me.sh

This should open Flexbe and load the intended behavior (see tips extras directory on how to change the flexbe original code to accept commands by default) which currently is Acquire\_Everything. Now you can run the behavior and select the appropriate run conditions in the parameter board thing. This will load the approapriate nodes depending on what you chose and will start `rqt_acquisition` which is an rqt plugin built specifically to guide you through the data acquisition process with the specific setup we have in our lab. Luckily this is just a python script, so if you are doing something similar, it shouldn't be too hard to change it to your needs. 


#### Option 2: More manual way of doing things

Run:

    ./devel_run_docker_image.sh

This should start the docker bash shell. Source the workspace:

    source /catkin_ws/devel/setup.bash

Then run the `flexbe_app`with

    roslaunch acquisition_of_raw_data all.launch

Load the behavior `Acquire_everything` and setup the appropriate acquisition parameters. 

This will skip the pre setup tests and you may accidentally close the docker instance, which can cause data loss (say if you saved things in directories that are not mounted volumes). Also you will have to type more things, so we recommend for everyday use going with option 1 and just altering what you need for your own setup, since there are quite a few steps to get this working and we want to simplify all the parts we can simplify.

## Final notes:

It is unfortunate that this system is not small enough for me to be on top of everything that needed to be fixed and I no longer work in this lab, so I may not be able to fix all the issues (since I soon won't be able to have access to the hardware required to use it).

## Changelog:

15 Nov 24: added `rqt_acquisition` plugin to allow for more flexibility on running the state machine.

12 Sep 24: moved this branch to opensim 4.5.1. Note that I haven't optimized this at all, so it is a massive docker image.  



# Structure Overview

The code was devided into 2 different workspaces to reduce compilation times so `opensimrt_core` can be compiled during the build script and the main catkin workspace can be compiled at runtime. This allowed us to share catkin\_ws as a docker volume and make sure that code changes are not lost between multiple sessions. My initial intention was to keep on simplifying the interface to make it more generic and easier to follow, but unfortunately even though this whole project is basically just a bunch of wrappers, the current code balooned out of control. Some things have become salient over time though:


- an opensim model should be a package. It makes sense to put its urdf/xacro definitions in it as well. Probably it also makes sense to put bundle files here as well, since probably some marker geometries make more sense with some models. 
- I think the way to place the imus or plates on the urdf model is to have tinier urdf models and set their origins to the places in the skeleton where you placed them (this will also simplify the xacros in the gait1992 package)
- Things that don't change should be moved into the docker itself so that we don't waste time recompiling it. My initial idea was to have everything in the same place once this was stable enough


# Docker builds

## Latest build

If you don't build the dockerfile, docker will try to download the latest version by default. This will likely work, but if you are in a system with multiple users, there might be some issues with volume mounts and playing sound (Pulse is a bit tricky to setup properly so you may need to use aplay instead of paplay, which will fail - note that aplay doesnt mix, so you may have device busy complaints when trying to play sound). It is just safer to build it again for your current user.

## Older builds

If instead you just want to use the older already built docker images, you can get them [here](https://hub.docker.com/r/mysablehats/opensim-rt/tags). We are not freezing versions, so it is possible that the builder script will break in the future. 

The docker with the default version from mitkof6/OpenSIMRT can be obtained with: 

     docker pull mysablehats/opensim-rt:main

It can also be directly accessed [here](https://hub.docker.com/layers/mysablehats/opensim-rt/main/images/sha256-f3f238759e736f2fd01b9a1eec307b9dbe664f97206e438541bb2685b9fcb38e).

# Using AR

Your camera needs to be calibrated and the fiducials need to be printed. More details in https://github.com/opensimrt-ros/ar_test


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

The X server for MacOS is XQuartz. It may have the same limitations as Windows visualization, but this has not been tested. The current version of this code doesn't seem to work with ARM based processors, so it won't run on some Mac models. 

