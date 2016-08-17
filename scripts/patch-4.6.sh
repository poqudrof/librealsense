#!/bin/bash -e

## package for linux
## wget https://www.archlinux.org/packages/core/x86_64/linux/


SRC_VERSION_NAME=linux-4.6
SRC_VERSION_ID=4.6.4


SRC_VERSION_REL=1

### untar
tar xf linux-4.6.tar.xz
cd linux-4.6

### patch
 xz -dc ../patch-4.6.5.xz  | patch -p1
###  patch2
 patch -p1 -i ../change-default-console-loglevel.patch

## Copy the config
cat ../config.x86_64 > ./.config


# Apply our RealSense specific patch
patch -p1 < ../scripts/realsense-camera-formats.patch


## CONFIG_LOCATION=/usr/src/linux-headers-$RAW_TAG*-generic/
# cp /usr/lib/modules/4.6.4-1-MANJARO/build/.config .
# cp /usr/lib/modules/4.6.4-1-MANJARO/build/Module.symvers .

# CONFIG_LOCATION=/usr/lib/modules/4.6.4-1-MANJARO/build

# Prepare to compile modules
#cp $CONFIG_LOCATION/.config .
# cp $CONFIG_LOCATION/Module.symvers .

make scripts oldconfig modules_prepare

# Compile UVC modules
echo "Beginning compilation of uvc..."
#make modules
KBASE=`pwd`
cd drivers/media/usb/uvc
cp $KBASE/Module.symvers .
make -C $KBASE M=$KBASE/drivers/media/usb/uvc/ modules

# Copy to sane location
sudo cp $KBASE/drivers/media/usb/uvc/uvcvideo.ko ~/$LINUX_BRANCH-uvcvideo.ko

# Unload existing module if installed
echo "Unloading existing uvcvideo driver..."
sudo modprobe -r uvcvideo

# Delete existing module
sudo rm /lib/modules/`uname -r`/kernel/drivers/media/usb/uvc/uvcvideo.ko

# Copy out to module directory
sudo cp ~/$LINUX_BRANCH-uvcvideo.ko /lib/modules/`uname -r`/kernel/drivers/media/usb/uvc/uvcvideo.ko

echo "Script has completed. Please consult the installation guide for further instruction."
