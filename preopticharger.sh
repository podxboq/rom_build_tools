#!/bin/bash

# Author: adumont (Adlx)
# We cache the optimized apk and save the md5 of the original apk
# If we try to opticharge again the same apk (same md5) we use the same optimized apk from cache
# Cache is held at $OUT/.opticharger

OPTICHARGER=$SCRIPTDIR/opticharger.sh

OPTICACHE=$OUT/.opticharger
[ -d ${OPTICACHE} ] || mkdir -p ${OPTICACHE}

. $SCRIPTDIR/mensajes.sh

A=$1

#LatinIME da errores si se modifica.
[ "$1" = "./LatinIME.apk" ] && exit 0

if [ -e "${A}" -a -e ${OPTICACHE}/${A}.md5 -a -e ${OPTICACHE}/${A}.opt ]
then
	if [ "$( md5sum ${A} | awk '{ print $1 }' )" = "$( cat ${OPTICACHE}/${A}.md5 )" ]
	then
		msgList "Optimizando" "$( basename $A ) (cache)"
		cp ${OPTICACHE}/${A}.opt ${A}
		exit 0
	fi
fi

# guardamos el md5 del original en cache
md5sum ${A} | awk '{ print $1 }' > ${OPTICACHE}/${A}.md5

# si acaso existe el ${OPTICACHE}/${A}, lo borramos
[ -e ${OPTICACHE}/${A}.opt ] && rm ${OPTICACHE}/${A}.opt

$OPTICHARGER $A

cp ${A} ${OPTICACHE}/${A}.opt
