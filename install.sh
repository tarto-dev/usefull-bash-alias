#!/bin/bash

## CONFIG VARS
BASE_PATH="/home/www/environnement_dev/bcassinat"
SAVE_PATH="$BASE_PATH/bashbak"

## GET SYSTEM OS
unameOut="$(uname -s)"
case "${unameOut}" in
  Linux*)     OS_BASED=linux;;
  Darwin*)    OS_BASED=macos;;
  *)          OS_BASED="UNKNOWN:${unameOut}"
esac

## BUILD THE FILES LIST
SOURCE_FILES=(".bash_aliases" ".bash_ps1" ".gitconfig" ".bash_completion")
if [ "$OS_BASED" == "linux" ];then 
  SOURCE_FILES+=(".bashrc")
else
  SOURCE_FILES+=(".bash_profile")
fi

## Will copy existents settings and move new one
move_profile() {
  echo -e "##### move_profile #####"

  mkdir -p $SAVE_PATH
  MOVED=0
  COPIED=0

  for i in ${SOURCE_FILES[@]}; do
    if [ -f $BASE_PATH/$i ]; then
      ((++MOVED))
      mv $BASE_PATH/$i $SAVE_PATH/$i
      echo -e "Fichier $BASE_PATH/$i déplacé"
    else
      ((++COPIED))
      cp $SAVE_PATH/files/$i $BASE_PATH/$i
      echo -e "Fichier $BASE_PATH/$i crée "
    fi
  done

  echo -e "L'installation à déplacé $MOVED fichiers et en a copiés $COPIED \n"
}

get_profile() {
  echo -e "##### get_profile #####"
  git clone --depth=1 --branch=master git://github.com/benftwc/usefull-bash-alias.git $SAVE_PATH/files
  rm -rf $SAVE_PATH/files/.git
}

confirm_installation() {
ERR=false
  for i in ${SOURCE_FILES[@]}; do
    if [ ! -f "$BASE_PATH/$i" ]; then
      ERR=true
      FIL=$BASE_PATH/$i
    fi
  done;

  if [ "$ERR" == "true" ]; then
    echo -e "\n\nERREUR D'INSTALLATION AVEC LE FICHIER $FIL - OUVREZ UNE ISSUE https://github.com/benftwc/usefull-bash-alias/issues\n\n"
  else
    echo -e "\n\nCUSTOM BASH DE BENFTWC CORRECTEMENT INSTALLE. ENJOY :)\n\n"
  fi
}

get_profile && move_profile && confirm_installation
