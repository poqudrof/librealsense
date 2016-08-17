#!/bin/bash -e

SRC_VERSION_NAME=linux
SRC_VERSION_ID=4.6.5

SRC_VERSION_REL=1
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

echo "Patching the kernel..."
### patch  not working ?
# xz -dc ../$PATCH_NAME.xz  | patch -p1


###  patch2 not sure...
## see in pkgbuild  https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/linux
# patch -p1 -i ../change-default-console-loglevel.patch

## Copy the config
## Same here, not sure... ?
# cat ../config.x86_64 > ./.config


 echo "RealSense patch..."

# Apply our RealSense specific patch
patch -p1 < ../../realsense-camera-formats.patch


## CONFIG_LOCATION=/usr/src/linux-headers-$RAW_TAG*-generic/
# cp /usr/lib/modules/4.6.4-1-MANJARO/build/.config .
# cp /usr/lib/modules/4.6.4-1-MANJARO/build/Module.symvers .


# CONFIG_LOCATION=/usr/lib/modules/4.6.4-1-MANJARO/build

# Prepare to compile modules
#cp $CONFIG_LOCATION/.config .
#cp $CONFIG_LOCATION/Module.symvers .

## Get the config
# zcat /proc/config.gz > .config

cp /usr/lib/modules/$SRC_VERSION_ID-1-MANJARO/build/.config .
cp /usr/lib/modules/$SRC_VERSION_ID-1-MANJARO/build/Module.symvers .


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

# cp $KBASE/drivers/media/usb/uvc/uvcvideo.ko ../../../../../../$LINUX_BRANCH-uvcvideo.ko
cp $KBASE/drivers/media/usb/uvc/uvcvideo.ko ../uvcvideo.ko

# Unload existing module if installed
#echo "Unloading existing uvcvideo driver..."
#sudo modprobe -r uvcvideo

cd ..
xz -k uvcvideo.ko

## Not sure yet about deleting and copying...

# Delete existing module
# sudo rm /lib/modules/`uname -r`/kernel/drivers/media/usb/uvc/uvcvideo.ko

# Copy out to module directory
# sudo cp ~/$LINUX_BRANCH-uvcvideo.ko /lib/modules/`uname -r`/kernel/drivers/media/usb/uvc/uvcvideo.ko

echo "Script has completed. Please consult the installation guide for further instruction."
