#!/bin/bash

MSG=$1

function banner() {
  local s="$*"
  tput setaf 3
  echo " --------------------${s//?/-}--------------------
 ${s//?/ }                                       
              $(tput setaf 4)$s$(tput setaf 3)      
 ${s//?/ }                                       
 --------------------${s//?/-}--------------------"
  tput sgr 0
}

banner $MSG
