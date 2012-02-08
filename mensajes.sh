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
#Colores
YELLOW="\033[1;33m" #el primer número es 1 (negrita); después el color
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
BLUEs="\033[1;36m"
WHITE="\033[1;37m"
ENDCOLOR="\033[0m"

ECHO="echo -e"

msgErr(){
  $ECHO $RED"$1"$ENDCOLOR
}

msgWarn(){
  $ECHO $BLUE"$1"$ENDCOLOR
}

msgOK(){
  $ECHO $GREEN"$1"$ENDCOLOR
}

msgInfo(){
  $ECHO $WHITE"$1"$ENDCOLOR
}

msgStatus(){
  $ECHO $YELLOW"$1"$ENDCOLOR
}

msgList(){
  $ECHO $YELLOW"$1: "$GREEN"$2"$ENDCOLOR
}

