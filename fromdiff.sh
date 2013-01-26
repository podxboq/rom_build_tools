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


#Inicializamos las variables
#!/bin/bash

SCRIPTDIR=`dirname $0`
. $SCRIPTDIR/mensajes.sh

if [ $# -lt 3 ]
then
   msgErr >&2 "Usage: $0 <file> <dir|device> <release|patch>"
   exit 1
fi

DIFFFILE=$1
ORIG=$2
DEST=$3
DEVICE=$4
if [ -z $DEVICE ]
then
	DEVICE=false
fi

if $DEVICE
then
	preDir=system
fi

mLANG=`echo $LANG | cut -f 2 -d "=" | cut -f 1 -d "."`

if [ $mLANG = "es_ES" ]; then
	mONLY="Sólo "
	mFILES="Archivos "
else
	mONLY="Only "
	mFILES="Files "
fi

if [ ! -f $DIFFFILE ]
then
    msgErr >&2 "El fichero $DIFFFILE no existe"
    exit 1
fi

if ! $DEVICE && [ ! -d $DEST ]
then
    msgErr >&2 "El directorio $DEST no existe"
    exit 1
fi

#borramos los ficheros que no están y copiamos los cambiados.

if $DEVICE
then
	adb remount
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
        	accion=copiar
        	prefile=${line#*$ORIG*}
			prefile=${prefile/: //}
        fi
    fi
    
	file=`echo $prefile | cut -d " " -f 1`
        
    if [[ $accion == "copiar" ]]
    then
    	if [ -d $ORIG$file ] && [ ! -d $DEST$file ]
    	then
    		mkdir -p $DEST$file
    	fi

        if $DEVICE
        then
			if [[ "$file" =~ "/bin/" ]] || [[ "$file" =~ "/xbin/" ]]
			then
				chmod 755 $ORIG$file
			fi
            adb push $ORIG$file $preDir$file
			if [[ "$file" == "/build.prop" ]]
			then
				adb shell chmod 644 $ORIG$file
			fi
        else
            cp -rv $ORIG$file $DEST$file
        fi
    fi

    if [[ $accion == "borrar" ]]
    then
        if $DEVICE
        then
        	msgWarn "borrando $preDir$file"
            adb shell rm -r $preDir$file
        else
        	msgWarn "borrando $DEST$file"
        	rm -r $DEST$file
    	fi
    fi
done < $DIFFFILE

if $DEVICE
then
    adb remount
fi
	
exit 0
