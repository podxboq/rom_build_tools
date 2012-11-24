#!/bin/bash

# Copyright (C) 2012 SuperTeam Development Group.
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
SCRIPTDIR=`dirname $0`
TOPDIR=`pwd`
. $SCRIPTDIR/mensajes.sh

DEVICES=(osr_bravo-eng osr_dragon-userdebug osr_galaxysmtd-userdebug osr_grouper-userdebug osr_hackberry-userdebug osr_i9100-userdebug osr_i9300-userdebug osr_mk802-userdebug osr_n7000-userdebug osr_pyramid-userdebug osr_tf201-userdebug)
CONFIGFILE=$HOME/.SuperOSR.conf
ROMDIR=$TOPDIR/../cache/nightly
[ ! -d $ROMDIR ] && mkdir -p $ROMDIR
LOGFILE=$TOPDIR/build.`date -u +%y%m%d`.log

#Buscamos valores personalizados para el build
if [ -f $CONFIGFILE ]; then
	CORES=$( grep CORES $CONFIGFILE | cut -f 2 -d "=" )
	if [ -z "$CORES" ]; then
		CORES=$( cat /proc/cpuinfo | grep -c processor )
	fi
	USE_CCACHE=$( grep USE_CCACHE $CONFIGFILE | cut -f 2 -d "=" )
	if [ -n "$USE_CCACHE" ] && [ "$USE_CCACHE" = "1" ]; then
		export USE_CCACHE=1
	else
		unset USE_CCACHE
	fi
fi

# repo sync
. build/envsetup.sh
#for DEVICE in "${DEVICES[@]}"; do
DEVICE=$1
	echo "****** $DEVICE"
	echo "****** $DEVICE" >> $LOGFILE
        lunch $DEVICE 2>>$LOGFILE
    if [ "$?" -eq 0 ]; then
        make clean
        make -j${CORES} otapackage 2>>$LOGFILE 
        if [ "$?" -eq 0 ]; then
            SQUISHER=`find vendor -name squisher*`
            $SQUISHER 2>>$LOGFILE
        fi
    fi
#done
	
