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

#
# Firma ficheros para instalar en el dispositivo. 
#

. mensajes.sh

OUT_TARGET_HOST=linux-x86
SECURITYDIR=$ANDROID_BUILD_TOP/build/target/product/security

msgStatus "Firmando el fichero $1"
	
java -Xmx1000m \
  -jar $ANDROID_BUILD_TOP/out/host/$OUT_TARGET_HOST/framework/signapk.jar \
  -w $SECURITYDIR/testkey.x509.pem $SECURITYDIR/testkey.pk8 \
  $1 $2
if [ "$?" -ne 0 ]; then
    msgErr "Error al firmar el fichero $1"
    exit 1
fi

# Crear md5 para el paquete firmado

img=`basename $2`
cd `dirname $2`
md5sum $img > $img.md5sum
msgOK "Paquete creado: $2"
msgOK `cat $img.md5sum`

exit 0
