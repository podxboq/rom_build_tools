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

SCRIPTDIR=`dirname $0`
. $SCRIPTDIR/mensajes.sh

if [ $# -lt 3 ]
then
   msgErr >&2 "Usage: $0 <dir1> <dir2> <file>"
   exit 1
fi

if [ ! -d $1 ]
then
    msgErr >&2 "El directorio $1 no existe"
    exit 1
fi

if [ ! -d $2 ]
then
    msgErr >&2 "El directorio $2 no existe"
    exit 1
fi

if [ -f $3 ]; then
	rm $3
fi
    	
msgStatus "Calculando las diferencias entre los directorios $1 y $2"
exec diff -qr $1 $2 | sort > $3

if [ "$?" -eq 0 ]; 
then
	msgOK "Diferencias obtenidas en el fichero $3"
	exit 0
else
    msgErr "No se ha podido obtener las diferencias correctamente"
    exit 1
fi