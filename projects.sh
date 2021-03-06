#!/bin/bash
# Copyright (C) 2011, 2012, 2013 podxboq
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
UPSTREAMFILE=$MAINDIR/fork.xml
PERSONALFILE=$MAINDIR/personal.xml
BLACKFILE=$MAINDIR/black.xml
REMOTEFILE=$MAINDIR/remotes.xml
GREEN="\033[1;32m"
RED="\033[1;31m"
COLOROFF="\033[0m"

function getProjectList(){
  PROJECTLIST=`xmllint --xpath '//project/@path' $TOPDIR/$XMLFILE`
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
  mRemoteURL=`xmllint --xpath 'string(//remote[@name="'$1'"]/@fetch)' $REMOTEFILE`
}

function getBranch(){
  mBranch=`xmllint --xpath 'string(//project[@'$1']/@revision)' $XMLFILE`
  if [ -z $mBranch ]; then
    mBranch=`xmllint --xpath 'string(//remote[@name="'$mRemote'"]/@revision)' $REMOTEFILE`
  fi
  mTag=false
  mBranch=${mBranch:=$DefBranch}
  if [[ "$mBranch" =~ "refs/tags" ]]; then
    mBranch=${mBranch#"refs/tags/"}
    mTag=true
  fi
}

function getUpstream(){
  unset mUpstreamRemote
  unset mUpstreamName
  unset mUpstreamBranch
  if [ -f $UPSTREAMFILE ]; then
    total_upstream_list=`xmllint --xpath 'count(//project[@'$1'])' $UPSTREAMFILE`
    for n in `seq 1 $total_upstream_list`
    do
      data=`xmllint --xpath '//project[@'$1'][position()='$n']/@remote' $UPSTREAMFILE`
      mUpstreamRemote[$n]=`echo $data | cut -d "\"" -f 2`
      data=`xmllint --xpath '//project[@'$1'][position()='$n']/@name' $UPSTREAMFILE`
      mUpstreamName[$n]=`echo $data | cut -d "\"" -f 2`
      data=`xmllint --xpath '//project[@'$1'][position()='$n']/@revision' $UPSTREAMFILE`
      #get project revision
      mUpstreamBranch[$n]=`echo $data | cut -d "\"" -f 2`
      #if not, get remote revision
      if [ -z "${mUpstreamBranch[n]}" ]; then
        mUpstreamBranch[$n]=`xmllint --xpath 'string(//remote[@name="'${mUpstreamRemote[n]}'"]/@revision)' $REMOTEFILE`
      fi
      #if not, get main default revision
      if [ -z "${mUpstreamBranch[n]}" ]; then
        mUpstreamBranch[$n]=$DefBranch
      fi
    done
  fi
}

function gitPull(){
  if [ ! -z $mPath ]; then
    cd $mPath
    if [ ! $mTag ]; then
      $GIT pull origin $mBranch
    fi
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

function gitCheckout(){
  cd $mPath
  $GIT checkout -- .
  if $mTag; then
    $GIT fetch --tags
    $GIT checkout $mBranch
  else
    $GIT checkout -b $mBranch origin/$mBranch
  fi
  cd $TOPDIR
}

function gitMerge(){
  cd $mPath
  total_upstream_list=${#mUpstreamRemote[@]}
  for ((a=1; a <= total_upstream_list ; a++)); do
    $GIT merge ${mUpstreamRemote[a]}/${mUpstreamBranch[a]}
  done
  cd $TOPDIR
}

function gitClone(){
  echo -e $GREEN"Cloning........."$COLOROFF
  if [[ -d $mPath ]]; then
    echo -e "Se va a clonar de nuevo el projecto $RED$mPath$COLOROFF, ¿desea borrarlo para reclonarlo (S/n)?"
    read option
    if [ -z $option ] || [ "$option" = "s" ]; then
      rm -rf $mPath
    else
      return
    fi
  fi
  if $mTag; then
    $GIT clone $mRemoteURL$mName $mPath
    cd $mPath 
    $GIT fetch --tags
    $GIT checkout $mBranch
    cd $TOPDIR
  else
    $GIT clone $mRemoteURL$mName $mPath -b $mBranch
  fi
  total_upstream_list=${#mUpstreamRemote[@]}
  for ((a=1; a <= total_upstream_list ; a++)); do
    getRemoteURL ${mUpstreamRemote[a]}
    cd $mPath
    $GIT remote add -t ${mUpstreamBranch[a]} ${mUpstreamRemote[a]} $mRemoteURL${mUpstreamName[a]}
    $GIT fetch ${mUpstreamRemote[a]} --tags
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

function gitSync(){
  if [ ! -f $mPath/.git/config ]; then
    gitClone
  else
    isSameServer $d
    if [ $? -eq 1 ]; then
      echo -e "Se ha cambiado el servidor del proyecto $RED$mPath$COLOROFF, ¿desea borrarlo para clonarlo (S/n)?"
      read option
      if [ -z $option ] || [ "$option" = "s" ]; then
        rm -rf $mPath
        gitClone
      fi
    else
      isSameBranch $d
      if [ $? -eq 1 ]; then
        echo -e "Se ha cambiado la rama del proyecto $RED$mPath$COLOROFF, ¿desea cambiarse (S/n)?"
        read option
        if [ -z $option ] || [ "$option" = "s" ]; then
          gitCheckout
        fi
      else
        gitPull
      fi
    fi
  fi
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

function isSameServer(){
  cd $mPath
  oldRemote=`$GIT config --get remote.origin.url`
  cd $TOPDIR
  if [ ! $oldRemote = $mRemoteURL$mName ]; then
    echo "$oldRemote -> $mRemoteURL$mName"
    return 1
  fi
  return 0
}

function isSameBranch(){
  cd $mPath
  oldBranch=`$GIT rev-parse --abbrev-ref HEAD`
  cd $TOPDIR
    if [ $oldBranch = "HEAD" ]; then
    return 0
  fi;
  if [ ! $oldBranch = $mBranch ]; then
    echo "$oldBranch -> $mBranch"
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
  DefRemote=`xmllint --xpath 'string(//default/@remote)' $REMOTEFILE`
  DefBranch=`xmllint --xpath 'string(//default/@revision)' $REMOTEFILE`
}
  
setDefEnv

if [ -z $3 ]; then
  getProjectList
else
  PROJECTLIST="path=\""$3"\""
fi

for d in $PROJECTLIST; do
  setEnv $d
  if [ -z $mPath ]; then
    continue
  fi
  isBlackProject $mPath
  if [ $? -eq 0 ]; then
    continue
  fi

  isPersonalProject $mPath
  if [ $? -eq 0 ]; then
    continue
  fi

  if [ "$1" = status ]; then
    if [ -d $mPath ]; then
      gitStatus
    fi
  elif [ "$1" = resync ]; then
    rm -rf $mPath
    gitClone
  elif [ "$1" = init ]; then
    if [ ! -d $mPath ]; then
      gitClone
    fi
  elif [ "$1" = push ]; then
      gitPush
  elif [ "$1" = sync ]; then
    gitSync
  elif [ "$1" = fullsync ]; then
    gitSync
    gitMerge
  fi
done
