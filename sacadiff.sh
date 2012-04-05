#!/bin/bash

# Copyright (C) 2011-2012 The SuperTeam Developer Group.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SCRIPTDIR=`dirname $0`
. $SCRIPTDIR/mensajes.sh

ORIG=$1
DEST=$2
DIFFFILE=$3
BASEDIR=`dirname $DIFFFILE`
A=$BASEDIR/a.txt
B=$BASEDIR/b.txt
AB=$BASEDIR/ab.txt

if [ $# -lt 3 ]
then
	msgErr >&2 "Usage: $0 <dir1> <dir2> <file>"
	exit 1
fi

if [ ! -d $ORIG ]
then
	msgErr >&2 "El directorio $1 no existe"
	exit 1
fi

if [ ! -d $DEST ]
then
	msgErr >&2 "El directorio $DEST no existe"
	exit 1
fi

if [ -f $DIFFFILE ]; then
	rm $DIFFFILE
fi
		
msgStatus "Calculando las diferencias entre los directorios $ORIG y $DEST"
exec diff -qr $ORIG $DEST | sort -r -o $DIFFFILE 

rm $A
rm $B
rm $AB

mLANG=`echo $LANG | cut -f 2 -d "=" | cut -f 1 -d "."`

if [ $mLANG = "es_ES" ]; then
	mFILES="Archivos "
else
	mFILES="Files "
fi

while read line; do
	if [[ "$line" =~ "$mFILES" ]]
	then
		accion=copiar
		prefile=${line#*$ORIG*}
	else
		if [[ "$line" =~ "$DEST" ]]
		then
			accion=borrar
			prefile=${line#*$DEST*}
			prefile=${prefile/: //}
		else
			accion=nuevo
			prefile=${line#*$ORIG*}
			prefile=${prefile/: //}
		fi
	fi
	
	file=`echo $prefile | cut -d " " -f 1`
		
	if [[ $accion == "copiar" ]]
	then
		echo $ORIG$file >> $AB
		msgWarn $ORIG$file
	fi

	if [[ $accion == "nuevo" ]]
	then
		echo $ORIG$file >> $A
		msgOK $ORIG$file
		fi

	if [[ $accion == "borrar" ]]
	then
		echo $ORIG$file >> $B
		msgErr $ORIG$file
		fi
done < $DIFFFILE

if [ "$?" -eq 0 ]; 
then
	msgOK "Diferencias obtenidas en el fichero $3"
	exit 0
else
	msgErr "No se ha podido obtener las diferencias correctamente"
	exit 1
fi