#!/usr/bin/env sh

######################################################################
# @author      : frekle (frekle@raspberrypi)
# @file        : rasppi
# @created     : Tuesday Dec 03, 2024 19:39:00 CET
#
# @description : 
######################################################################

USER_NAME=rosopensimrt

INSTALL_DIR=/home/$USER_NAME
COMMIT=b949681af69b45f0f7f4bb53b6770037b5b02178
pip3 install sense-hat
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

wget https://github.com/RPi-Distro/RTIMULib/archive/$COMMIT.zip
unzip $COMMIT
cd RTIMULib-$COMMIT/Linux/python/
python3 setup.py build
python3 setup.py install

sudo addgroup rosopensimrt input
