#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

if [ $# -ne 2 ]; then
	echo "number of args must be 2"
	exit 1
fi

cp -af $1/bootloader.img $2
exit $?
