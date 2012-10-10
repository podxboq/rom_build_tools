#!/bin/bash

# Copyright (C) 2011-2012 The SuperTeam Development Group
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

TOPDIR=`pwd`

if [ $# -lt 3 ]
then
	echo "Usage: $0 <directoryIn> <directoryOut> <resid>"
	exit 1
fi

function out(){
	TOTAL_LINES=`wc -l $2 | cut -d " " -f 1`
	INI_LINE=`grep -n "\"$1\"" $2 | tr -d : | cut -d " " -f 1`
	N_LAST_LINES=$(($TOTAL_LINES-$INI_LINE + 1))
	TAG=`grep "\"$1\"" $2 | cut -d "<" -f 2 | cut -d " " -f 1`
	FIN_TAG_LINE=`tail -n $N_LAST_LINES $2 | grep -m 1 -n "</$TAG>" | tr -d : | cut -d " " -f 1`
	BLOCK_LINE=$(($INI_LINE+$FIN_TAG_LINE))
	tail -n $N_LAST_LINES $2 | head -n $FIN_TAG_LINE
}

cd $1
FILES=`grep -r "\"$3\"" . | cut -d ":" -f 1`
for f in $FILES; do
	FULL_PATH_FILE=$TOPDIR/$2$f 
	cd $TOPDIR/$2
	TOTAL_LINES=`wc -l $f | cut -d " " -f 1`
	head -n $(($TOTAL_LINES - 1)) $f > $FULL_PATH_FILE.tmp
	cd $TOPDIR/$1
	out $3 $TOPDIR/$1$f >> $FULL_PATH_FILE.tmp
	echo >> $FULL_PATH_FILE.tmp
	cd $TOPDIR/$2
	tail -n 1 $f >> $FULL_PATH_FILE.tmp
	cat $FULL_PATH_FILE.tmp
	mv $FULL_PATH_FILE.tmp $FULL_PATH_FILE
done;
