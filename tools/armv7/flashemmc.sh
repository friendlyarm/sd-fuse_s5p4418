#!/bin/bash

#----------------------------------------------------------
# mount fs

DATA_DIR=/tmp/media

if [ ! -d ${DATA_DIR} -a -b /dev/mmcblk0p1 ]; then
	mkdir -p ${DATA_DIR}
	mount /dev/mmcblk0p1 ${DATA_DIR}
fi

#----------------------------------------------------------
# get config

ROM_BASE=${DATA_DIR}/images
IMG_CONF=${ROM_BASE}/FriendlyARM.ini

if [ ! -f ${IMG_CONF} ]; then
	echo "Error: File ${IMG_CONF} not found, stop"
	exit -1
fi

function read_conf()
{
	local var="/^$1/ { print $2(\$2) }"
	echo `gawk -F= -e "${var}" ${IMG_CONF} | sed 's/\r//g'`
}

OS=$(read_conf OS tolower)
ACTION=$(read_conf Action tolower)
IMAGES=$(read_conf Images-${OS})

if [ -z ${OS} -o "${ACTION}" != "install" ]; then
	echo "Error: Invalid config in FriendlyARM.ini"
	exit -1
fi

#----------------------------------------------------------
# prepare images

if [ ! -d ${ROM_BASE} ]; then
	echo "Warn: NanoPi2 images not found, stop."
	exit -1
fi

if [ ! -d ${ROM_BASE}/${OS} ]; then
	(cd ${ROM_BASE} && md5sum -c ${IMAGES}.hash.md5 2>/dev/null)
	if [[ "$?" != 0 ]]; then
		echo "Error: Validating $IMAGES failed"
		exit -1
	fi

	mkdir -p ${ROM_BASE}/${OS}
	tar xzvf ${ROM_BASE}/${IMAGES} -C ${ROM_BASE}/${OS} || {
		echo "Error: Unpacking  $IMAGES failed"
		exit -1
	}
fi

#----------------------------------------------------------
# do fusing

BASE_DIR=/usr/sd-fuse_nanopi2

export BOOT_DIR=${BASE_DIR}/prebuilt

export SD_FUSING=${BASE_DIR}/fusing.sh
export FW_SETENV=${BASE_DIR}/tools/armv7/fw_setenv
export SD_UPDATE=${BASE_DIR}/tools/armv7/sd_update
export SD_TUNEFS=${BASE_DIR}/tools/sd_tune2fs.sh

cd ${ROM_BASE} && {
	${SD_FUSING} /dev/mmcblk1 ${OS}
}

