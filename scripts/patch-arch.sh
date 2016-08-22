#!/bin/bash -e

SRC_VERSION_NAME=linux

## from
## http://stackoverflow.com/questions/9293887/in-bash-how-do-i-convert-a-space-delimited-string-into-an-array

FULL_NAME=$( uname -r | tr "-" "\n")
read -a VERSION <<< $LINUX

SRC_VERSION_ID=${VERSION[0]}  ## e.g. : 4.5.6
SRC_VERSION_REL=${VERSION[1]} ## e.g. : 1
LINUX_TYPE=${VERSION[2]}      ## e.g. : ARCH

ARCH=x86_64

LINUX_BRANCH=archlinux-$SRC_VERSION_ID

# ARCH --  KERNEL_NAME=linux-$SRC_VERSION_ID-$SRC_VERSION_REL-$ARCH.pkg.tar.xz
KERNEL_NAME=linux-$SRC_VERSION_ID
PATCH_NAME=patch-$SRC_VERSION_ID

mkdir kernel
cd kernel

## Get the kernel
wget https://www.kernel.org/pub/linux/kernel/v4.x/$KERNEL_NAME.tar.xz
wget https://www.kernel.org/pub/linux/kernel/v4.x/$PATCH_NAME.xz
wget https://www.kernel.org/pub/linux/kernel/v4.x/$PATCH_NAME.sign

echo "Extract the kernel"
tar xf $KERNEL_NAME.tar.xz

cd $KERNEL_NAME

## Get the patch

# echo "Patching the kernel..."
### patch  not working ?
# xz -dc ../$PATCH_NAME.xz  | patch -p1


echo "RealSense patch..."

# Apply our RealSense specific patch
patch -p1 < ../../realsense-camera-formats.patch

# Prepare to compile modules

## Get the config
# zcat /proc/config.gz > .config  ## Not the good one ?

cp /usr/lib/modules/$FULL_NAME/build/.config .
cp /usr/lib/modules/$FULL_NAME/build/Module.symvers .

echo "Prepare the build"

make scripts oldconfig modules_prepare

# Compile UVC modules
echo "Beginning compilation of uvc..."
#make modules
KBASE=`pwd`
cd drivers/media/usb/uvc
cp $KBASE/Module.symvers .
make -C $KBASE M=$KBASE/drivers/media/usb/uvc/ modules

# Copy to sane location
#sudo cp $KBASE/drivers/media/usb/uvc/uvcvideo.ko ~/$LINUX_BRANCH-uvcvideo.ko
cd ../../../../../

cp $KBASE/drivers/media/usb/uvc/uvcvideo.ko ../uvcvideo.ko

# Unload existing module if installed
echo "Unloading existing uvcvideo driver..."
sudo modprobe -r uvcvideo

cd ..
xz -k uvcvideo.ko

## Not sure yet about deleting and copying...

# save the existing module
sudo cp /lib/modules/$LINUX_BRANCH/kernel/drivers/media/usb/uvc/uvcvideo.ko.backup
sudo cp /lib/modules/$LINUX_BRANCH/kernel/drivers/media/usb/uvc/uvcvideo.ko.xz.backup

# Delete existing module
sudo rm /lib/modules/$LINUX_BRANCH/kernel/drivers/media/usb/uvc/uvcvideo.ko
sudo rm /lib/modules/$LINUX_BRANCH/kernel/drivers/media/usb/uvc/uvcvideo.ko.xz

# Copy out to module directory
sudo cp uvcvideo.ko.xz /lib/modules/$LINUX_BRANCH/kernel/drivers/media/usb/uvc/

sudo modprobe uvcvideo

echo "Script has completed. Please consult the installation guide for further instruction."
