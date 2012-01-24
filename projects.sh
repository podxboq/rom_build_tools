#!/bin/bash
# Copyright (C) 2011 The Superteam Development Group
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

function getBranch(){
	mBranch=`xmllint --xpath 'string(//project[@'$1']/@revision)' $XMLFILE`
	if [[ "$mBranch" =~ "refs/tags" ]]; then
    	mBranch=${mBranch#"refs/tags/"}
    fi
	mBranch=${mBranch:=$DefBranch}
}

function getUpstream(){
	unset mUpstreamRemote
	unset mUpstreamBranch
	total_upstream_list=`xmllint --xpath 'count(//project[@'$1'])' $UPSTREAMFILE`
	for ((a=1; a <= total_upstream_list ; a++)); do
		mUpstreamRemote[$a]=`xmllint --xpath 'string(//project[@'$1' and position()='$a']/@remote)' $UPSTREAMFILE`
		#get project revision
		mUpstreamBranch[$a]=`xmllint --xpath 'string(//project[@'$1' and position()='$a']/@revision)' $UPSTREAMFILE`
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
	done
}

function gitPull(){
	if [ ! -z $mPath ]; then
		cd $mPath
		$GIT pull origin $mBranch
		total_upstream_list=${#mUpstreamRemote[@]}
		for ((a=1; a <= total_upstream_list ; a++)); do
			$GIT fetch ${mUpstreamRemote[a]}
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
	echo -e $GREEN"Cloning $mPath"$COLOROFF
	$GIT clone $mRemoteURL$mName $mPath -b $mBranch
	total_upstream_list=${#mUpstreamRemote[@]}
	for ((a=1; a <= total_upstream_list ; a++)); do
		getRemoteURL ${mUpstreamRemote[a]}
		cd $mPath
		$GIT remote add ${mUpstreamRemote[a]} $mRemoteURL${mUpstreamName[a]}
		$GIT fetch ${mUpstreamRemote[a]}
		cd $TOPDIR
	done
}

function gitStatus(){
	cd $mPath
	STATUS=`$GIT status`
	if [[ "$STATUS" =~ "Changes" ]] || [[ "$STATUS" =~ "Untracked" ]]; then
		echo -e $GREEN $mPath $COLOROFF
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
}

function isSameProject(){
	oldRemote=`xmllint --xpath 'string(//project[@'$1']/@remote)' $OLDXMLFILE`
	oldRemote=${oldRemote:=$DefOldRemote}
	if [ ! $oldRemote = $mRemote ]; then
		return 1
	fi
	oldName=`xmllint --xpath 'string(//project[@'$1']/@name)' $OLDXMLFILE`
		if [ ! $oldName = $mName ]; then
		return 1
	fi
	return 0
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
		DefOldRemote=`xmllint --xpath 'string(//default/@remote)' $OLDXMLFILE`
	else
		DefOldRemote=$DefRemote
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
		echo -e "Se ha quitado la ruta$RED$oldpath$COLOROFF de la lista de proyectos."
		echo "¿Quiere borrarlo (N/s)?"
		read option
		if [ "$option" = s ]; then
			rm -rf $oldpath
		fi
	fi
done

for d in $PROJECTLIST; do
	setEnv $d
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
	  	echo -e $GREEN $mPath $COLOROFF
	  	isSameProject $d
	  	if [ $? -eq 1 ]; then
			echo -e "Se ha cambiado el servidor del proyecto $RED $oldpath$COLOROFF, se borra para clonarlo."
	  		rm -rf $mPath
	  	fi

		if [ -d $mPath ]; then
			gitPull
		else
			gitClone
		fi
	elif [ "$1" = fullsync ]; then
	  	echo -e $GREEN $mPath $COLOROFF

		if [ -d $mPath ]; then
			gitPull
			gitUpstream
		else
			gitClone
		fi
	fi
done
