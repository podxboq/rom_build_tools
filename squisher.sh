#!/bin/bash
#
# Squish a otapackage for distribution
#

#Inicializamos las variables
export VENDOR=vendor/podxboq
MODS=$VENDOR/mods
OTAPACKAGE=$OUT/$PRODUCT_ROM_FILE-ota.zip
OPTICHARGER=$SCRIPTDIR/preopticharger.sh
QUIET=-q
DELETE_BINS="applypatch applypatch_static check_prereq recovery updater"
squash_opts="-force-uid 1000 -force-gid 1000 -no-progress -noappend -no-exports -no-recovery"
REPACK=$OUT/repack.d
REPACKOTA=$REPACK/ota

CORES=$( cat /proc/cpuinfo | grep -c processor )
TOPDIR=`pwd`
SECURITYDIR=$ANDROID_BUILD_TOP/build/target/product/security

. $SCRIPTDIR/mensajes.sh

# Verificación de entorno de desarrollo operativo
if [ -z "$OUT" -o ! -d "$OUT" ]; then
	msgErr "$0 solo funciona con un entorno completo de desarrollo. $OUT debe existir."
	exit 1
fi

# Se verifica que existe el fichero inicial.
if [ ! -f "$OTAPACKAGE" ]; then
	msgErr "$OTAPACKAGE no existe!"
	exit 1
fi

# Elimina cualquier directorio de un trabajo antiguo
clear
msgInfo "Limpiando el entorno..."
rm -rf $REPACK
mkdir -p $REPACKOTA
(
cd $REPACKOTA
msgInfo "Copiando ficheros"
cp -rf $OUT/system $REPACKOTA
unzip -nq $OTAPACKAGE -d $REPACKOTA
echo
)

# Copiado de archivos comunes
[ -d $ANDROID_BUILD_TOP/$MODS/common ] && cp -rf $ANDROID_BUILD_TOP/$MODS/common/* $REPACKOTA/

# Copiado de archivos específicos
[ -d $ANDROID_BUILD_TOP/$MODS/$ALIAS ] && cp -rf $ANDROID_BUILD_TOP/$MODS/$ALIAS/* $REPACKOTA/

#Ejecuta opticharger sobre el resto de apks de la rom
cd $REPACKOTA/system/app
find ./ -name \*.apk | xargs --max-args=1 --max-procs=${CORES} $OPTICHARGER
cd $REPACKOTA/system/framework
$OPTICHARGER framework-res.apk

# Corregir build.prop
sed -i \
  -e '/ro\.kernel\.android\.checkjni/d' \
  -e '/ro\.build\.date\.utc/s/.*/ro.build.date.utc=0/' \
  $REPACKOTA/system/build.prop

# Eliminar binarios innecesarios
cd $REPACKOTA/system/bin
$ECHO $DELETE_BINS | xargs rm -f

# No se necesita recovery (en caso de existir)
rm -rf $REPACKOTA/recovery

# Strip modulos
[ -d $REPACKOTA/system/lib/modules ] && \
	find $REPACKOTA/system/lib/modules -name "*.ko" -print0 | xargs -0 arm-eabi-strip --strip-unneeded

exit 0
