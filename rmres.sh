#!/bin/bash

# Copyright (C) 2011-2013 The SuperTeam Development Group.
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

if [ $# -lt 1 ]
then
	echo "Usage: $0 <resid>..."
	exit 1
fi

cd $TOPDIR
for res in "$@"; do
	FILES=`grep -r "name=\"$res\"" res/ | cut -d ":" -f 1`
	for f in $FILES; do
		sed '/name="'$res'"/d' $f > newfile.tmp
		mv newfile.tmp $f
	done;
done;

