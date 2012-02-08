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

isDIR=false
BUILDMASK=last_build
RELEASEMASK=last_release
PATCHMASK=last_patch
PUBLICMASK=last_public

SCRIPTDIR=`dirname $0`
. $SCRIPTDIR/mensajes.sh

if [ $# -lt 3 ]
then
   msgErr >&2 "Usage: $0 <file> <dir|device> <release|patch>"
   exit 1
fi

DIFFFILE=$1
DEST=$2
ENV=$3
mLANG=`echo $LANG | cut -f 2 -d "=" | cut -f 1 -d "."`

if [ $mLANG = "es_ES" ]; then
	mONLY="Sólo"
	mONLYIN="Sólo en "
	mAND=" y"
	mFILES="Archivos "
else
	mONLY="Only"
	mONLYIN="Only in "
	mAND=" and"
	mFILES="Files"
fi

if [ ! -f $DIFFFILE ]
then
    msgErr >&2 "El fichero $DIFFFILE no existe"
    exit 1
fi

#comprobamos si el segundo parámetro es un directorio o el dispositivo
#se diferencia en que el dispositivo no puede llevar el caracter /
if [[ "$DEST" =~ "/" ]]; then
	isDIR=true
fi

if $isDIR && [ ! -d $DEST ]
then
    msgErr >&2 "El directorio $DEST no existe"
    exit 1
fi

if [ "$ENV" == "release" ]
then
	MASK=$RELEASEMASK
else
    MASK=$PATCHMASK
fi

#borramos los ficheros que no están y copiamos los cambiados.

if ! $isDIR
then
	adb remount
fi

while read line; do
    if [[ "$line" =~ "$BUILDMASK" ]]; then
		if [[ "$line" =~ "$mONLY" ]]; then
            base=${line#*$mONLYIN*}
            file=${base/: //}
		else
            base=${line%*$mAND*}
            file=${base#*$mFILES*}
		fi
        accion=copiar
    else
        base=${line#*$mONLYIN*}
        file=${base/: //}
        accion=borrar
    fi
    
    if [[ $accion == "copiar" ]]; then
    	FINALDIR=${file/build/$ENV}
    	if [ ! -d $file ]; then
    	   FINALDIR=${FINALDIR%*/*}
    	fi
    	if [ ! -d $FINALDIR ]; then
    		mkdir -p $FINALDIR
    	fi

        if $isDIR
        then
        	if [ -d $file ]
        	then
                cp -rv $file/* ${file/build/$ENV}
        	else
                cp -v $file ${file/build/$ENV}
            fi
        else
            adb push $file .${file#*$BUILDMASK*}
			if [[ "$file" =~ "/bin/" ]]
			then
				adb shell chmod 755 .${file#*$BUILDMASK*}
			fi
        fi
    fi

    if [[ $accion == "borrar" ]]; then
    	if [[ $ENV == "patch" ]]; then
    		if [ -d $file ]; then
    			echo "rm -r ${file#*$PUBLICMASK*}" >> $DEST/rm.sh
    		else
    			echo "rm ${file#*$PUBLICMASK*}" >> $DEST/rm.sh
    		fi
    	else
	        msgWarn "borrando $file"
	        if $isDIR
	        then
	        	rm -r $file
	        else
	            adb shell rm -r .${file#*$MASK*}
	        fi
    	fi
    fi
done < $DIFFFILE

if ! $isDIR
then
    adb remount
fi
	
exit 0	
