#!/bin/bash
# Copyright (C) 2013 The SuperTeam Development Group.
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
ROMPACKAGE=$OUT/$PRODUCT_ROM_FILE.zip
REPACK=$OUT/repack.d
REPACKOTA=$REPACK/ota

. $SCRIPTDIR/mensajes.sh

# Se verifica que existe el directorio de trabajo.
if [ ! -d "$REPACKOTA" ]; then
	msgErr "$REPACKOTA no existe!"
	exit 1
fi

cd $REPACKOTA
[ -e $REPACK/update.zip ] && rm -f $REPACK/update.zip

msgStatus "Comprimiendo ROM usando zip"
time zip -rqy --symlinks -9 $REPACK/update.zip . 

firmar.sh $REPACK/update.zip $ROMPACKAGE
if [ "$?" -ne 0 ]; then
	msgErr "Error al obtener el fichero firmado $ROMPACKAGE"
	exit 1
fi

exit 0
