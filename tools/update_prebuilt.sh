#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

cp -f $2/bl1-mmcboot.bin $1/
cp -f $2/loader-mmc.img $1/
cp -f $2/bl_mon.img $1/
[ ! -f $1/userdata.img ] && cp -f $2/userdata.img $1/

if [ ! -f $1/env.conf ]; then
    cp -f $2/env.conf $1/
fi

exit $?
