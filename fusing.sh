#!/bin/bash

# Copyright (C) Guangzhou FriendlyARM Computer Tech. Co., Ltd.
# (http://www.friendlyarm.com)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, you can access it online at
# http://www.gnu.org/licenses/gpl-2.0.html.

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
	sudo "$0" "$@"
	exit
fi

# ----------------------------------------------------------
# Checking device for fusing

if [ -z $1 ]; then
	echo "Usage: $0 DEVICE [android|debian]"
	exit 0
fi

case $1 in
/dev/sd[a-z] | /dev/loop[0-9] | /dev/mmcblk1)
	if [ ! -e $1 ]; then
		echo "Error: $1 does not exist."
		exit 1
	fi
	DEV_NAME=`basename $1`
	BLOCK_CNT=`cat /sys/block/${DEV_NAME}/size` ;;&
/dev/sd[a-z])
	DEV_PART=${DEV_NAME}2
	REMOVABLE=`cat /sys/block/${DEV_NAME}/removable` ;;
/dev/mmcblk1 | /dev/loop[0-9])
	DEV_PART=${DEV_NAME}p2
	REMOVABLE=1 ;;
*)
	echo "Error: Unsupported SD reader"
	exit 0
esac

if [ ${REMOVABLE} -le 0 ]; then
	echo "Error: $1 is non-removable device. Stop."
	exit 1
fi

if [ -z ${BLOCK_CNT} -o ${BLOCK_CNT} -le 0 ]; then
	echo "Error: $1 is inaccessible. Stop fusing now!"
	exit 1
fi

let DEV_SIZE=${BLOCK_CNT}/2
if [ ${DEV_SIZE} -gt 64000000 ]; then
	echo "Error: $1 size (${DEV_SIZE} KB) is too large"
	exit 1
fi

if [ ${DEV_SIZE} -le 3800000 ]; then
	echo "Error: $1 size (${DEV_SIZE} KB) is too small"
	echo "       At least 4GB SDHC card is required, please try another card."
	exit 1
fi

# ----------------------------------------------------------
# Get target OS

true ${TARGET_OS:=${2,,}}

case ${2,,} in
debian | core-qte | rtmsystem | eflasher)
	PARTMAP=./${TARGET_OS}/partmap.txt
	;;
*)
	TARGET_OS=android
	PARTMAP=./${TARGET_OS}/partmap.txt
	if [ ! -z ${ANDROID_PRODUCT_OUT} ]; then
		PARTMAP=${ANDROID_PRODUCT_OUT}/partmap.txt
	fi
	;;
esac

if [ ! -f ${PARTMAP} ]; then
	echo -n "Warn: Image not found for ${TARGET_OS^}, download now (Y/N)? "

	while read -r -n 1 -t 10 -s USER_REPLY; do
		if [[ ${USER_REPLY} = [Nn] ]]; then
			echo ${USER_REPLY}
			exit 1
		elif [[ ${USER_REPLY} = [Yy] ]]; then
			echo ${USER_REPLY}
			break;
		fi
	done

	if [ -z ${USER_REPLY} ]; then
		echo "Cancelled."
		exit 1
	fi

	./tools/get_rom.sh ${TARGET_OS} || exit 1
fi

# ----------------------------------------------------------
# Get host machine
if grep 'ARMv7 Processor' /proc/cpuinfo >/dev/null; then
#	EMMC=.emmc
	ARCH=armv7/
fi

# ----------------------------------------------------------
# Fusing 2ndboot, bootloader to card

true ${BOOT_DIR:=./prebuilt}

BL2_BIN=${BOOT_DIR}/2ndboot.bin${EMMC}
BL2_POSITION=1

TBI_BIN=${BOOT_DIR}/boot.TBI
TBI_POSITION=64

BL3_BIN=${BOOT_DIR}/bootloader
BL3_POSITION=65

# umount all at first
umount /dev/${DEV_NAME}* > /dev/null 2>&1

echo "---------------------------------"
echo "2ndboot fusing"
dd if=${BL2_BIN} of=/dev/${DEV_NAME} bs=512 seek=${BL2_POSITION}

echo "---------------------------------"
echo "bootloader fusing"
dd if=${TBI_BIN} of=/dev/${DEV_NAME} bs=512 seek=${TBI_POSITION} count=1
dd if=${BL3_BIN} of=/dev/${DEV_NAME} bs=512 seek=${BL3_POSITION}

#<Message Display>
echo "---------------------------------"
echo "Bootloader image is fused successfully."
echo ""

# ----------------------------------------------------------
# partition card & fusing filesystem

true ${FW_SETENV:=./tools/${ARCH}fw_setenv}
true ${SD_UPDATE:=./tools/${ARCH}sd_update}
true ${SD_TUNEFS:=./tools/sd_tune2fs.sh}

echo "---------------------------------"
echo "${TARGET_OS^} filesystem fusing"
echo "Image root: `dirname ${PARTMAP}`"
echo

if [ ! -f ${PARTMAP} ]; then
	echo "Error: ${PARTMAP}: File not found"
	echo "       Stop fusing now"
	exit 1
fi

# set uboot env, like cmdline
if [ -f ./${TARGET_OS}/env.conf ]; then
	${FW_SETENV} /dev/${DEV_NAME} -s ./${TARGET_OS}/env.conf
elif [ -f ${BOOT_DIR}/${TARGET_OS}_env.conf ]; then
	${FW_SETENV} /dev/${DEV_NAME} -s ${BOOT_DIR}/${TARGET_OS}_env.conf
else
	${FW_SETENV} /dev/${DEV_NAME} -s ${BOOT_DIR}/generic_env.conf
fi

# write ext4 image
${SD_UPDATE} -d /dev/${DEV_NAME} -p ${PARTMAP}
if [ $? -ne 0 ]; then
	echo "Error: filesystem fusing failed, Stop."
	exit 1
fi

if [ -z ${ARCH} ]; then
	partprobe /dev/${DEV_NAME} -s 2>/dev/null
fi
if [ $? -ne 0 ]; then
	echo "Warn: Re-read the partition table failed"

else
	# optional: update uuid & label
	if [ "x${TARGET_OS}" = "xandroid" ]; then
		sleep 1
		${SD_TUNEFS} /dev/${DEV_NAME}
	elif [ "x${TARGET_OS}" = "xdebian" ]; then
		sleep 1
		resize2fs -f /dev/${DEV_PART}
	fi
fi

echo "---------------------------------"
echo "${TARGET_OS^} is fused successfully."
echo "All done."

