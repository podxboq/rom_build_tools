#!/bin/bash

# Copyright (C) 2011-2012 The SuperTeam Developer Group.
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
ROMDIR=$1
RELEASEDIR=$ROMDIR/last_release
PATCHDIR=$ROMDIR/last_patch
PUBLICDIR=$ROMDIR/last_public

. $SCRIPTDIR/mensajes.sh

if [ ! -d $RELEASEDIR ]; then
	msgErr "No existe el directorio $RELEASEDIR, se mueve la versión build y se obvia la gestión de cambios"
	mkdir -p $RELEASEDIR
	mv $OUT/system $RELEASEDIR
else
	msgStatus "Calculando las diferencias con la anterior versión compilada"
	$SCRIPTDIR/sacadiff.sh $OUT/repack.d/ota/system $RELEASEDIR/system $ROMDIR/diff.txt
	        
	#actualizamos el directorio de la última release
	msgOK "¿Actualizar el directorio? (s/N): "
	read sync
	
	case $sync in
		[sS] )
			$SCRIPTDIR/fromdiff.sh $ROMDIR/diff.txt $OUT/repack.d/ota/system $RELEASEDIR/system
	esac
		    
	#actualizamos el dispositivo
	msgOK "¿Actualizar el dispositivo? (s/N): "
	read sync
	
	case $sync in
		[sS] )
			$SCRIPTDIR/fromdiff.sh $ROMDIR/diff.txt $OUT/repack.d/ota/system $RELEASEDIR/system true
	esac
fi
    