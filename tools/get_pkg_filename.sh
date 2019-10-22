#!/bin/bash

TARGET_OS=${1,,}

case ${TARGET_OS} in
android)
        ROMFILE=android-lollipop-images.tgz;;
android7)
        ROMFILE=android-nougat-images.tgz;;
kitkat)
        ROMFILE=android-kitkat-images.tgz;;
friendlywrt)
        ROMFILE=friendlywrt-images.tgz;;
friendlycore)
        ROMFILE=friendlycore-images.tgz;;
lubuntu)
        ROMFILE=lubuntu-desktop-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=
esac
echo $ROMFILE
