#!/bin/bash
# Copyright (C) 2013 podxboq
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
TOPDIR=`pwd`
GIT=git
MAINDIR=android
XMLFILE=$MAINDIR/default.xml
OLDXMLFILE=`mktemp`
RED="\033[1;31m"
COLOROFF="\033[0m"

cp $XMLFILE $OLDXMLFILE
cd $MAINDIR
$GIT fetch origin $mBranch
$GIT pull origin $mBranch
cd $TOPDIR

PROJECTLIST=`xmllint --xpath '//project/@path' $TOPDIR/$XMLFILE`
OLDPROJECTLIST=`xmllint --xpath '//project/@path' $OLDXMLFILE`

for d in $OLDPROJECTLIST; do
  if ! [[ $PROJECTLIST =~ $d ]]; then
    oldpath=`xmllint --xpath 'string(//project[@'$d']/@path)' $OLDXMLFILE`
    echo -e "Se ha quitado la ruta $RED$oldpath$COLOROFF de la lista de proyectos."
    echo "¿Quiere borrarlo (s/N)?"
    read option
    if [ "$option" = s ]; then
      rm -rf $oldpath
    fi
  fi
done
