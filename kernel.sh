#!/bin/bash

# Copyright (C) 2011 SuperTeam.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#Inicializamos las variables
TOPDIR=`pwd`
DEVICEDIR=`find device -type d -name $1`
DEFFILE=$DEVICEDIR/kernel.mk
KERNELDIR=`grep ST_KERNEL_DIR $DEFFILE | cut -d "=" -f 2` 
KERNELCFG=`grep ST_KERNEL_CFG $DEFFILE | cut -d "=" -f 2`
KERNELIMG=`grep ST_KERNEL_IMG $DEFFILE | cut -d "=" -f 2`
KERNELDIR=${KERNELDIR, 1}
KERNELCFG=${KERNELCFG, 1}
KERNELIMG=${KERNELIMG, 1}

if [ ! -d $OUT/obj/kernel ]; then
	mkdir -p $OUT/obj/kernel
fi

cp -f $KERNELCFG $OUT/obj/kernel/.config

make menuconfig CC="ccache arm-eabi-gcc" -C $KERNELDIR O=$OUT/obj/kernel \
     ARCH=arm INSTALL_MOD_STRIP=1 \
     CROSS_COMPILE=$TOPDIR/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi- \
     zImage modules

cp -fv $OUT/obj/kernel/.config $KERNELCFG
cp -fv $OUT/obj/kernel/arch/arm/boot/zImage $KERNELIMG
