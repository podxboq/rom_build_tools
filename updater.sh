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
#
#Inicializamos las variables
SCRIPTDIR=`dirname $0`
TOPDIR=`pwd`
DEVICE=$1
ROMDIR=$TOPDIR/../cache/roms/$DEVICE
PATCHDIR=$ROMDIR/last_patch
SCRIPTFILE=$PATCHDIR/META-INF/com/google/android/updater-script
DEVICEDIR=`find device -type d -name $1`

. $SCRIPTDIR/mensajes.sh

OSRZIP=`grep ro.modversion $SCRIPTDIR/../products/team_$1.mk | cut -f 2 -d "=" | cut -f 1 -d " "`
OSRVER=`grep ro.stats.romversion $SCRIPTDIR/../products/team_$1.mk | cut -f 2 -d "=" | cut -f 1 -d " "`
AOSPVER=`grep "PLATFORM_VERSION :=" $TOPDIR/build/core/version_defaults.mk | cut -f 2 -d "="`
AOSPVER=${AOSPVER:1}

function write_mount (){
	mFS=`grep ST_$1_FS $DEVICEDIR/updater.mk | cut -d "=" -f 2`
	mBK=`grep ST_$1_BLOCK $DEVICEDIR/updater.mk | cut -d "=" -f 2`
	mNM=`grep ST_$1_NAME $DEVICEDIR/updater.mk | cut -d "=" -f 2`
	mDV=`grep ST_$1_DEV $DEVICEDIR/updater.mk | cut -d "=" -f 2`
	mMT=`grep ST_$1_METHOD $DEVICEDIR/updater.mk | cut -d "=" -f 2`
	if [ "$1" = "BOOT" ]; then
		if [ "${mMT:1}" = "raw" ]; then
			echo "package_extract_file(\"boot.img\", \"/tmp/boot.img\");" >> $SCRIPTFILE
			echo "write_raw_image(\"/tmp/boot.img\", \""${mDV:1}"\");" >> $SCRIPTFILE
		else
			echo "package_extract_file(\"boot.img\", \""${mDV:1}"\");" >> $SCRIPTFILE
		fi
	else
		echo "mount(\""${mFS:1}"\", \""${mBK:1}"\", \""${mDV:1}"\", \""${mNM:1}"\");" >> $SCRIPTFILE
	fi
}

#Descomprimimos lo ficheros base para el instalador
if [ -d $PATCHDIR/META-INF ]; then
	rm -r $PATCHDIR/META-INF
fi
unzip $OUT/$OSRZIP.zip META-INF/com/google/android/update-binary -d $PATCHDIR
unzip $OUT/$OSRZIP.zip META-INF/CERT.RSA -d $PATCHDIR

#Creamos el script del instalador
echo "ui_print(\"Instalando parche para "$DEVICE"\");" >> $SCRIPTFILE
echo "ui_print(\"SuperOSR "$OSRVER" con Android "$AOSPVER".\");" >> $SCRIPTFILE
write_mount SYSTEM
write_mount DATA
#Por motivos de espacio, primero borramos lo que sobra.
if [ -f $PATCHDIR/rm.sh ]; then
	echo "package_extract_file(\"rm.sh\", \"/tmp/rm.sh\");" >> $SCRIPTFILE
	echo "set_perm(0, 0, 06755, \"/tmp/rm.sh\");" >> $SCRIPTFILE
	echo "run_program(\"/sbin/sh\");" >> $SCRIPTFILE
fi
echo "package_extract_dir(\"system\", \"/system\");" >> $SCRIPTFILE
echo "package_extract_dir(\"data\", \"/data\");" >> $SCRIPTFILE
echo "unmount(\"/system\");" >> $SCRIPTFILE
echo "unmount(\"/data\");" >> $SCRIPTFILE
if [ -f $PATCHDIR/boot.img ]; then
	write_mount BOOT
fi
echo "ui_print(\"Parche instalado. Gracias.\");" >> $SCRIPTFILE

msgStatus "Ya puede modificar el contenido de $PATCHDIR. Confirme para continuar"
	
read var

cd $PATCHDIR
msgStatus "Comprimiendo parche"
rm ../update.zip
zip -qr ../update.zip .
UPDATEFILE=$OUT/SuperOSR-$1-$OSRVER.zip
cd $TOPDIR
$SCRIPTDIR/firmar.sh $ROMDIR/update.zip $UPDATEFILE
if [ "$?" -eq 0 ]; then
	msgOK "Fichero $UPDATEFILE creado correctamente"
else
    msgErr "Error al firmar el fichero $UPDATEFILE"
    exit -1
fi
	    
exit 0