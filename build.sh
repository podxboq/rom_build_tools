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
MAINFILE=`find device -name team_$1.mk`
SUBDEVICE=`grep -G ^PRODUCT_SUBDEVICE $MAINFILE`
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

. $SCRIPTDIR/mensajes.sh

if [ $# -lt 1 ]
then
	msgErr >&2 "Usage: $0 <device>"
	exit 1
fi

function compilar(){
	#borramos los objetos para forzar que se copie la ROM entera
	rm -r $OUT/recovery $OUT/root $OUT/system $OUT/kernel
    make -j${CORES} otapackage
	if [ "$?" -eq 0 ]; then
	    msgOK "Compilación correcta"
	else
	    msgErr "Error en compilación"
	    FAIL=true
	fi
}	 

function squishear(){
	SQUISHER=`find vendor -name squisher*`
	$SQUISHER
	if [ "$?" -eq 0 ]; then
	    msgOK "Personalización correcta"
	else
	    msgErr "Error al ejecutar squisher"
	    FAIL=true
	fi
}

function reiniciar(){
	echo "1: Normal"
	echo "2: Recovery"
	echo "3: HBoot"
	echo "4: Apagar"
	read option
	if [ ! -z $option ]
	then
		case $option in
			1) adb reboot
			;;
			2) adb reboot recovery
			;;
			3) adb reboot bootloader
			;;
			4) adb shell halt
			
		esac
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

function makeClean(){
	echo "¿Estás seguro que quieres empezar de cero? (s/N)"
	read option
	option=${option:="N"}
	if [ "$option" = "s" ] || [ "$option" = "S" ]; then
		echo "make clean"
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
    echo " 7: Reiniciar/Apagar dispositivo"
    echo " 8: Compilar kernel"
    echo " 9: Cambiar boot"
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
    		makeClean
    		;;
    	7)
    		reiniciar
    		;;
    	8)	
    		$SCRIPTDIR/kernel.sh $DEVICE
    		;;
    	9)
    		fastboot flash boot $OUT/boot.img
    esac    
done
	
