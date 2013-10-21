#!/bin/bash

# Copyright (C) 2011-2013 SuperTeam Development Group.
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
SCRIPTDIR=`readlink $0`
if [ $SCRIPTDIR = "" ]
then
  SCRIPTDIR=`dirname $0`
else
  SCRIPTDIR=`dirname $0`/`dirname $SCRIPTDIR`
fi

TOPDIR=`pwd`
. $SCRIPTDIR/mensajes.sh
LOGFILE=error.log

if [ $# -gt 3 ] || [ $# -lt 1 ]
then
  msgErr "Usage: $0 <device> [organization] [buildtype]"
  exit 1
fi

DEVICE=$1
ORG=$2
if [ "$ORG" == "" ]
then
  ORG=osr
fi

BUILD=$3
if [ "$BUILD" == "" ]
then
  BUILD=eng
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

function compilar(){
  #borramos los objetos para forzar que se copie la ROM entera
  rm -rf $OUT/recovery $OUT/root $OUT/system $OUT/kernel 2&> /dev/null
  make -j${CORES} otapackage 2> $LOGFILE
  if [ "$?" -eq 0 ]; then
      msgOK "Compilación correcta"
  else
      msgErr "Error en compilación"
      FAIL=true
  fi
}   

function squishear(){
  $SCRIPTDIR/squisher.sh
  if [ "$?" -eq 0 ]; then
      msgOK "Personalización correcta"
  else
      msgErr "Error al ejecutar squisher"
      FAIL=true
  fi
}

function zipear(){
  $SCRIPTDIR/zipear.sh
}

function buscar(){
  echo "Texto: "
  read text
  echo "1: Módulo"
  echo "2: Make"
  echo "3: C/C++"
  echo "4: Java"
  read option
  if [ ! -z $option ]
  then
    case $option in
      1) mgrep LOCAL_MODULE | grep $text\$;;
      2) mgrep "$text";;
      3) cgrep "$text";;
      4) jgrep "$text";;
    esac
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
      1) adb reboot;;
      2) adb reboot recovery;;
      3) adb reboot bootloader;;
      4) adb shell halt;;
    esac
  fi
}
  
function sincronizar(){
     $SCRIPTDIR/sincronizar.sh $ROMDIR
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
    make clean
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
  msgStatus "Compilando la rom del SuperTeam para el dispositivo $1"
  echo "Elige una opción:"
  echo " 1: make"
  echo " 2: squisher"
  echo " 3: zip"
  echo " 4: sincronizar"
  echo " 5: crear parche"
  echo " 6: make + squisher + zip + sincronizar"
  echo " 7: limpiar build"
  echo " 8: Reiniciar/Apagar dispositivo"
  echo " 9: Compilar kernel"
  echo "10: Cambiar boot"
  echo "11: Copiar ROM al dispositivo"
  echo "12: Buscar"
  echo "13: Ver fichero de errores"
  echo "99: salir"

  read option
    
  FAIL=false
    
  if [ $option -eq 99 ]; then
    exit 0
  fi

  if [ "$OUT" = "" ]; then
    . build/envsetup.sh
    lunch "$ORG"_"$DEVICE"-"$BUILD"
    if [ "$?" -ne 0 ]; then
      continue
    fi
  fi
    
  case $option in
    1) compilar;;
    2) squishear;;
    3) zipear;;
    4) sincronizar;;
    5) parchear;;
    6) compilar
       if ! $FAIL ; then
         squishear
       fi
       if ! $FAIL ; then
         sincronizar
       fi
       if ! $FAIL ; then
         zipear
       fi;;
    7) makeClean;;
    8) reiniciar;;
    9) $SCRIPTDIR/kernel.sh $DEVICE;;
    10) fastboot flash boot $OUT/boot.img;;
    11) echo "Copiando $OUT/$PRODUCT_ROM_FILE.zip"; adb remount; adb push $OUT/$PRODUCT_ROM_FILE.zip /mnt/sdcard/
        if [ "$?" -eq 0 ]; then
          msgOK "OK"
        else
          msgErr "Error al copiar la ROM"
        fi;;
    12) buscar;;
    13) cat $LOGFILE;;
  esac    
done
  