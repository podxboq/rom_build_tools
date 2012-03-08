#!/bin/bash
# Copyright (C) 2011, 2012 The Superteam Development Group
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
TOPDIR=`pwd`
GIT=git
MAINDIR=android
XMLFILE=$2
UPSTREAMFILE=$MAINDIR/upstreams.xml
PERSONALFILE=$MAINDIR/personal.xml
BLACKFILE=$MAINDIR/black.xml
OLDXMLFILE=`mktemp`
GREEN="\033[1;32m"
RED="\033[1;31m"
COLOROFF="\033[0m"

function getProjectList(){
	PROJECTLIST=`xmllint --xpath '//project/@path' $TOPDIR/$XMLFILE`
	OLDPROJECTLIST=`xmllint --xpath '//project/@path' $OLDXMLFILE`
}

function getPath(){
	mPath=`xmllint --xpath 'string(//project[@'$1']/@path)' $XMLFILE`
}

function getName(){
	mName=`xmllint --xpath 'string(//project[@'$1']/@name)' $XMLFILE`
}

function getRemote(){
	mRemote=`xmllint --xpath 'string(//project[@'$1']/@remote)' $XMLFILE`
	mRemote=${mRemote:=$DefRemote}
}

function getRemoteURL(){
	mRemoteURL=`xmllint --xpath 'string(//remote[@name="'$1'"]/@fetch)' $XMLFILE`
}

function getRemoteUpstreamURL(){
	mRemoteURL=`xmllint --xpath 'string(//remote[@name="'$1'"]/@fetch)' $UPSTREAMFILE`
}

function getBranch(){
	mBranch=`xmllint --xpath 'string(//project[@'$1']/@revision)' $XMLFILE`
	if [ -z $mBranch ]; then
		mBranch=`xmllint --xpath 'string(//remote[@name="'$mRemote'"]/@revision)' $XMLFILE`
	fi
	mTag=false
	if [[ "$mBranch" =~ "refs/tags" ]]; then
    	mBranch=${mBranch#"refs/tags/"}
    	mTag=true
    fi
	mBranch=${mBranch:=$DefBranch}
}

function getUpstream(){
	unset mUpstreamRemote
	unset mUpstreamName
	unset mUpstreamBranch
	if [ -f $UPSTREAMFILE ]; then
		total_upstream_list=`xmllint --xpath 'count(//project[@'$1'])' $UPSTREAMFILE`
		a=1
		for data in `xmllint --xpath '//project[@'$1']/@remote' $UPSTREAMFILE`; do
			mUpstreamRemote[$a]=`echo $data | cut -d "\"" -f 2`
			a=$a+1
		done
		a=1
		for data in `xmllint --xpath '//project[@'$1']/@name' $UPSTREAMFILE`; do
			mUpstreamName[$a]=`echo $data | cut -d "\"" -f 2`
			a=$a+1
		done
		a=1
		for data in `xmllint --xpath '//project[@'$1']/@revision' $UPSTREAMFILE`; do
			#get project revision
			mUpstreamBranch[$a]=`echo $data | cut -d "\"" -f 2`
			#if not, get remote revision
			if [ -z "${mUpstreamBranch[a]}" ]; then
				mUpstreamBranch[$a]=`xmllint --xpath 'string(//remote[@name="'${mUpstreamRemote[a]}'"]/@revision)' $UPSTREAMFILE`
			fi
			#if not, get default revision
			if [ -z "${mUpstreamBranch[a]}" ]; then
				mUpstreamBranch[$a]=`xmllint --xpath 'string(//default/@revision)' $UPSTREAMFILE`
			fi
			#if not, get main default revision
			if [ -z "${mUpstreamBranch[a]}" ]; then
				mUpstreamBranch[$a]=$DefBranch
			fi
			a=$a+1
		done
	fi
}

function gitPull(){
	isPersonalProject $mPath
	if [ $? -eq 0 ]; then
		return 0
	fi
	if [ ! -z $mPath ]; then
		cd $mPath
		$GIT pull origin $mBranch
		total_upstream_list=${#mUpstreamRemote[@]}
		for ((a=1; a <= total_upstream_list ; a++)); do
			$GIT fetch ${mUpstreamRemote[a]}
			$GIT merge ${mUpstreamRemote[a]}/${mUpstreamBranch[a]}
		done
		cd $TOPDIR
	fi
}

function gitPush(){
	if [ ! -z $mPath ]; then
		cd $mPath
		$GIT push origin $mBranch
		cd $TOPDIR
	fi
}

function gitUpstream(){
	cd $mPath
	total_upstream_list=${#mUpstreamRemote[@]}
	for ((a=1; a <= total_upstream_list ; a++)); do
		$GIT merge ${mUpstreamRemote[a]}/${mUpstreamBranch[a]}
	done
	cd $TOPDIR
}

function gitClone(){
	isPersonalProject $mPath
	if [ $? -eq 0 ]
	then
		return 0
	fi
	echo -e $GREEN"Cloning........."$COLOROFF
	if $mTag; then
		$GIT clone $mRemoteURL$mName $mPath
		cd $mPath 
		$GIT checkout $mBranch
		cd $TOPDIR
	else
		$GIT clone $mRemoteURL$mName $mPath -b $mBranch
	fi
	total_upstream_list=${#mUpstreamRemote[@]}
	for ((a=1; a <= total_upstream_list ; a++)); do
		getRemoteUpstreamURL ${mUpstreamRemote[a]}
		cd $mPath
		$GIT remote add -t ${mUpstreamBranch[a]} ${mUpstreamRemote[a]} $mRemoteURL${mUpstreamName[a]}
		$GIT fetch ${mUpstreamRemote[a]}
		cd $TOPDIR
	done
}

function gitStatus(){
	cd $mPath
	STATUS=`$GIT status`
	if [[ "$STATUS" =~ "Changes" ]] || [[ "$STATUS" =~ "Untracked" ]]; then
		$GIT status
	fi
	cd $TOPDIR
}

function setEnv(){
	getPath $1
	getRemote $1
	getBranch $1
	getRemoteURL $mRemote
	getName $1
	getUpstream $1
	echo -e $GREEN$mPath $COLOROFF
}

function isSameProject(){
	cd $mPath
	oldRemote=`$GIT config --get remote.origin.url`
	cd $TOPDIR
	if [ ! $oldRemote = $mRemoteURL$mName ]; then
		return 1
	fi
	return 0
}
		
function isPersonalProject(){
	if [ -f $PERSONALFILE ] && ! [ $PERSONALFILE = $XMLFILE ] 
	then
		if [ `xmllint --xpath 'count(//project[@path="'$1'"])' $PERSONALFILE` -gt 0 ]
		then
			return 0
		fi
	fi
	return 1
}

function isBlackProject(){
	if [ -f $BLACKFILE ]
	then
		if [ `xmllint --xpath 'count(//project[@path="'$1'"])' $BLACKFILE` -gt 0 ]
		then
			return 0
		fi
	fi
	return 1
}

function setDefEnv(){
	DefRemote=`xmllint --xpath 'string(//default/@remote)' $XMLFILE`
	DefBranch=`xmllint --xpath 'string(//default/@revision)' $XMLFILE`
	DefBranch=${DefBranch#"refs/heads/"}
}
 	
function init(){
	PullActions="sync init fullsync"
	if [[ -z ${PullActions%%*$1*} ]]; then
		cp $XMLFILE $OLDXMLFILE
		setEnv "path=\"$MAINDIR\""
		gitPull
		setDefEnv
	fi
}
 	
setDefEnv
init $1

if [ -z $3 ]; then
	getProjectList
else
	PROJECTLIST="path=\""$3"\""
fi

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

for d in $PROJECTLIST; do
	setEnv $d
	isBlackProject $mPath
	if [ $? -eq 0 ]
	then
		continue
	fi

	if [ "$1" = status ]; then
		if [ -d $mPath ]; then
			gitStatus
		fi
	elif [ "$1" = init ]; then
		if [ ! -d $mPath ]; then
			gitClone
		fi
	elif [ "$1" = push ]; then
			gitPush
	elif [ "$1" = sync ]; then
	  	if [ ! -d $mPath ] 
	  	then
	  		gitClone
		else
	  		isSameProject $d
		  	if [ $? -eq 1 ]
		  	then
				echo -e "Se ha cambiado el servidor del proyecto $RED$mPath$COLOROFF, se borra para clonarlo."
		  		rm -rf $mPath
				gitClone
			else
				gitPull
		  	fi
		fi
	elif [ "$1" = fullsync ]; then
		if [ -d $mPath ]; then
			gitPull
			gitUpstream
		else
			gitClone
		fi
	fi
done
