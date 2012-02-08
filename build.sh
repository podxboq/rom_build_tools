#!/bin/bash

# Copyright (C) 2011 SuperTeam Development Group.
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
SUBDEVICE=`grep -G ^PRODUCT_SUBDEVICE $TOPDIR/vendor/SuperTeam/products/team_$1.mk`
if [ -n $SUBDEVICE ]; then
	DEVICE=$1
else
	DEVICE=$SUBDEVICE
fi
ROMDIR=$TOPDIR/../cache/roms/$DEVICE
BUILDDIR=$ROMDIR/last_build
RELEASEDIR=$ROMDIR/last_release
PATCHDIR=$ROMDIR/last_patch
PUBLICDIR=$ROMDIR/last_public
CONFIGFILE=$HOME/.SuperOSR.conf

#Buscamos valores personalizados para el build
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

. $SCRIPTDIR/mensajes.sh

if [ $# -lt 1 ]
then
	msgErr >&2 "Usage: $0 <device>"
	exit 1
fi
	
$SCRIPTDIR/preparasource.sh $DEVICE

function compilar(){
    make -j${CORES} otapackage
	if [ "$?" -eq 0 ]; then
	    msgOK "Compilación correcta"
	else
	    msgErr "Error en compilación"
	    FAIL=true
	fi
}	 

function squishear(){
	$SCRIPTDIR/squisher
	if [ "$?" -eq 0 ]; then
	    msgOK "Personalización correcta"
	else
	    msgErr "Error al ejecutar squisher"
	    FAIL=true
	fi
}

function sincronizar(){
   	$SCRIPTDIR/sincronizar.sh $ROMDIR $DEVICE
	if [ "$?" -eq 0 ]; then
	    msgOK "Sincronización correcta"
	else
	    msgErr "Error al sincronizar"
	    FAIL=true
	fi
}

function parchear(){
	if [ ! -d $PUBLICDIR ]; then
		msgWarn "No existe un directorio con la versión actualmente publicada. Se crea uno nuevo. La propia ROM es el parche."
		cp -r $BUILDDIR $PUBLICDIR
	else
		if [ -d $PATCHDIR ]; then
			rm -r $PATCHDIR
		fi
		mkdir $PATCHDIR
		msgStatus "Calculando las diferencias con la anterior versión publicada"
		$SCRIPTDIR/sacadiff.sh $BUILDDIR $PUBLICDIR $ROMDIR/public.diff.txt
		$SCRIPTDIR/fromdiff.sh $ROMDIR/public.diff.txt $PATCHDIR patch
		$SCRIPTDIR/updater.sh $DEVICE
	fi
}
while true
do
    #inicializamos estados
    echo "Elige una opción:"
    echo " 1: make"
    echo " 2: squisher"
    echo " 3: sincronizar"
    echo " 4: crear parche"
    echo " 5: make + squisher + sincronizar"
    echo " 6: limpiar build"
    echo " 7: Reiniciar dispositivo"
    echo " 8: Compilar kernel"
    echo "99: salir"

    read option
    
    FAIL=false
    
    if [ $option -eq 99 ]; then
        exit 0
    fi

    if [ "$OUT" = "" ]; then
    	. build/envsetup.sh
    	lunch team_$DEVICE-eng
        if [ "$?" -ne 0 ]; then
            continue
        fi
    fi
    
    case $option in
    	1) 
    		compilar 
    		;;
		2) 
			squishear 
			;;
		3) 
			sincronizar 
			;;
		4)
			parchear
			;;
		5)
			compilar
			if ! $FAIL ; then
				squishear
			fi
			if ! $FAIL ; then
				sincronizar
			fi
			;;
    	6)
    		make clean
    		;;
    	7)
    		adb reboot
    		;;
    	8)	
    		$SCRIPTDIR/kernel.sh $DEVICE
    		;;
    esac    
done
	
