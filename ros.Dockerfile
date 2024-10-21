ARG start_with_image=ros:noetic-ros-base 
ARG IS_ROOTLESS=false
FROM ${start_with_image} AS stage1
ARG IS_ROOTLESS
ENV IS_ROOTLESS=${IS_ROOTLESS}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install \
	build-essential \
	curl \
	freeglut3-dev \
	git \
	libxi-dev \
	libxmu-dev \
	liblapack-dev \
	doxygen \
	gdb \
	cmake \
	wget \
	xz-utils \
	vim \
	python \
	v4l-utils \
	catkin-lint \
	iputils-ping \
	alsa-utils \
	pulseaudio \
	libasound2 \
	libasound2-plugins \
	libeigen3-dev \
	libfprint-2-2 \
	libpython-all-dev \
	libudev-dev \
	libudev1 \
	tmux \
	--yes

RUN apt-get install \
	ros-noetic-desktop-full \
	ros-noetic-moveit \
	ros-noetic-plotjuggler-ros \
	ros-noetic-rosdoc-lite \
	ros-noetic-rosbridge-server \
	--yes && rm -rf /var/lib/apt/lists/*


ADD scripts/configure_sound.bash /tmp/conf_alsa.bash
RUN /tmp/conf_alsa.bash

WORKDIR /opt/dependencies

RUN if [ "${download_precompiled_opensim}" = true ]; then \
	wget https://sourceforge.net/projects/dependencies/files/opensim-core/opensim-core-4.1-ubuntu-18.04.tar.xz && \
        tar --no-same-owner -xvf opensim-core-4.1-ubuntu-18.04.tar.xz && rm opensim-core-4.1-ubuntu-18.04.tar.xz \
    ;fi

RUN  wget https://sourceforge.net/projects/dependencies/files/oscpack/oscpack-ubuntu-18.04.tar.xz && \
        tar --no-same-owner -xvf oscpack-ubuntu-18.04.tar.xz && rm oscpack-ubuntu-18.04.tar.xz 

RUN  wget https://sourceforge.net/projects/dependencies/files/vicon/ViconDataStreamSDK_1.7.1_96542h.tar.xz && \
        tar --no-same-owner -xvf ViconDataStreamSDK_1.7.1_96542h.tar.xz && rm ViconDataStreamSDK_1.7.1_96542h.tar.xz

RUN git clone https://github.com/mysablehats/OpenSimRT_data.git /srv/data && cd /srv/data && git checkout 3b0aa9d31fd1b86458ff3bcafa8d5ce3411391b5

FROM stage1 AS stage2

ADD scripts/ximu.bash /bin
RUN /bin/ximu.bash

#FROM ros:noetic-ros-base AS build-env2

#COPY --from=build-env /srv/data /srv/data
#COPY --from=build-env /usr /usr
#COPY --from=build-env /lib /lib
#COPY --from=build-env /etc /etc
#COPY --from=build-env /bin /bin
#COPY --from=build-env /sbin /sbin
#COPY --from=build-env /opt /opt
#COPY --from=build-env /ximu3/libximu3.a /ximu3/libximu3.a


##this is a volume now so we can't build it at docker build time
#RUN bash catkin_build_ws.bash

## dynamic reconfigure has problems with newer versions of pyyaml
## also need pupil and nest for eye_tracker
RUN wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && python3 -m pip install --upgrade pynvim && \
	pip3 install --upgrade pip && hash -r && pip3 install --upgrade pip && pip3 install protobuf==3.20.1 mock numpy pupil-labs-realtime-api nest_asyncio && \
	pip3 install --ignore-installed PyYAML==5.3 

RUN echo "reinstall neovim"
ADD vim /nvim
ADD scripts/vim_install.bash /nvim
RUN /nvim/vim_install.bash
ADD tmux/.tmux.conf /etc/tmux

# Set user and group
ARG user=osruser1
ARG group=osruser1
ARG uid=1000
ARG gid=1000
#ARG VIDEOGROUP=${VIDEOGROUP}
#RUN groupadd -g $VIDEOGROUP video
RUN groupadd -g ${gid} ${group}

## opensimrtuser)
## generate other password with $ openssl passwd -6 "somepassword"
RUN useradd -l -u ${uid} -g ${gid} -G sudo,audio,video -s /bin/bash -m -p '$6$WsqPSjlIKm37devi$U3hwXWYilUOFYRH8EE7FoStlfCfeK0dJY3.fdEWKFJkDGMg6p9YQIsycpcv7OM4SFSdz3D0sfEGyrY8reNSgu1' ${user}
# Switch to user

ENV XDG_RUNTIME_DIR=/run/user/"${uid}"

WORKDIR /catkin_opensim/src


ENV OPENSIMRTDIR=opensimrt_core

#half way into removing those hardcoded paths. still hardcoded, but a bit better
ADD cmake/Findsimbody.cmake /opt/dependencies
ADD cmake/FindOpenSim.cmake /opt/dependencies

RUN git clone https://github.com/opensimrt-ros/opensimrt_core.git ./$OPENSIMRTDIR -b feature/epoch-time-saving  && ln -s /srv/data $OPENSIMRTDIR/data && cd /catkin_opensim/src/$OPENSIMRTDIR && git checkout d5efbb262bf14b20facf292d9d9fb886f6ac7e3b && cd ..
RUN sed 's@~@/opt@' ./$OPENSIMRTDIR/.github/workflows/env_variables >> /etc/profile.d/opensim_envs.sh

RUN git clone https://github.com/opensimrt-ros/opensimrt_msgs.git -b devel && cd opensimrt_msgs && git checkout 182dd0a73a3d8a822c8112eab03879490edee09a && cd ..
#RUN echo "I use this to make it get stuff from git again"

RUN git clone https://github.com/opensimrt-ros/opensimrt_bridge.git -b devel && cd opensimrt_bridge && git checkout 96d388fdfcc538e7be30bb8680fec316b4b594bf && cd ..

ENV PYTHONPATH=/opt/ros/noetic/lib/python3/dist-packages/:$PYTHONPATH

#I dont think this variable is set yet
ENV OPENSIM_PYTHON_DIR=/usr/local/lib/python3.8/site-packages
WORKDIR ${OPENSIM_PYTHON_DIR}
RUN python3.8 setup.py install
WORKDIR /usr/lib/x86_64-linux-gnu
RUN ln -s libpython3.8.so.1.0 libpython3.6m.so.1.0
## fixing bug in view_frames
RUN sed -i "s/\(subprocess.Popen([^)]*\)/\1,universal_newlines=True/" /opt/ros/noetic/lib/tf/view_frames 

ADD scripts/realsense_install.bash /usr/sbin/
RUN bash /usr/sbin/realsense_install.bash

RUN mkdir -p -m 0700 /var/run/dbus && chown ${uid}:${gid} /var/run/dbus && chown ${uid}:${gid} -R /catkin_opensim

USER ${uid}

ENV HOME_DIR=/home/${user}
ADD scripts/vim_configure.bash ${HOME_DIR}/
RUN ~/vim_configure.bash

ADD tmux/.tmux.conf ${HOME_DIR}/

ADD scripts/build_opensimrt.bash /bin/catkin_build_opensimrt.bash

ADD scripts/build_catkin_ws.bash /bin/catkin_build_ws.bash

RUN printf "source /catkin_ws/devel/setup.bash\nsource /catkin_opensim/devel/setup.bash" >> ~/.bash_history

###############################################################################################################################################################################################################################################
FROM stage2 AS stage3
#WORKDIR /catkin_opensim/src/opensimrt_core
#RUN git pull
WORKDIR /catkin_opensim
#RUN . /opt/ros/noetic/setup.sh && . /etc/profile.d/opensim_envs.sh && catkin_make ## it's not a session, so it wont load the exports...
RUN /bin/catkin_build_opensimrt.bash

WORKDIR /catkin_opensim/src

FROM stage3 AS final

#EXPOSE 8080/udp
#EXPOSE 8080/tcp

EXPOSE 9000/udp
EXPOSE 9001/udp
EXPOSE 10000/udp

EXPOSE 8001/udp
EXPOSE 8000/udp

EXPOSE 7000/tcp
#port for insoles
EXPOSE 9999

##BLING
ADD scripts/bash_git.bash ${HOME_DIR}/.bash_git
ADD scripts/bashbar.bash  ${HOME_DIR}/.bash_bar
RUN echo "source ~/.bash_git" >> ~/.bashrc && \
    echo "source ~/.bash_bar" >> ~/.bashrc && \
    echo "export EDITOR='nv'" >> ~/.bashrc && \
    echo "alias gedit=\"rosrun tmux_launch tmux_neovim.py\"" >> ~/.bashrc && \
    echo 'export PATH=${PATH}:/catkin_ws/src/tmux_launch/scripts/' >> ~/.bashrc

ADD scripts/create_bashrcs.bash ${HOME_DIR}/.create_bashrcs.sh
RUN bash ~/.create_bashrcs.sh
#ADD tmux/ /usr/local/bin # moved to a volume

ADD scripts/catkin.sh /bin/first_time_catkin_builder.sh

## gets latest local environment
ADD scripts/set_local_branches.bash /bin/set_local_branches.bash
#ADD scripts/get_latest_local_branches.bash /bin/get_latest_local_branches.bash
WORKDIR /catkin_ws
#RUN apt remove python -y
#RUN apt install cowsay -y

RUN rosdep update
RUN pip3 install timeout_decorator libtmux sympy tqdm pandas

WORKDIR ${HOME_DIR}
RUN git clone https://github.com/mrocklin/multipolyfit.git \
	&& cd multipolyfit \
	&& git checkout a83e3241e07a32ef9298e288201bde5779f69538 \ 
	&& pip3 install -e .

WORKDIR /catkin_ws

ADD scripts/banners /etc/banners
ADD scripts/banners/welcome.sh /etc/profile.d/welcome.sh

USER root
RUN set -eux; \
	apt-get update; \
	apt-get install -y gosu; \
	apt install -y python-gi python3-gi \
    gstreamer1.0-tools \
    gir1.2-gstreamer-1.0 \
    gir1.2-gst-plugins-base-1.0 \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav; \
	rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
	gosu nobody true

ADD scripts/entrypoint.sh /bin/entrypoint.sh 
ENTRYPOINT [ "entrypoint.sh" ]
