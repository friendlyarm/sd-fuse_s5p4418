#!/bin/bash

TARGET_OS=$(echo ${1,,}|sed 's/\///g')
case ${TARGET_OS} in
android)
        ROMFILE=android-lollipop-images.tgz;;
android7)
        ROMFILE=android-nougat-images.tgz;;
kitkat)
        ROMFILE=android-kitkat-images.tgz;;
friendlywrt)
        ROMFILE=friendlywrt-images.tgz;;
friendlycore*)
        # don't cut TARGET_OS off
        ROMFILE=${TARGET_OS}-images.tgz;;
lubuntu)
        ROMFILE=lubuntu-desktop-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=
esac
echo $ROMFILE
