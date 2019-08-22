#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
        echo "Re-running script under sudo..."
        sudo "$0" "$@"
        exit
fi

true ${SOC:=s5p4418}
ARCH=arm
KIMG=arch/${ARCH}/boot/zImage
KDTB=arch/${ARCH}/boot/dts/s5p4418-nanopi2-*.dtb
OUT=${PWD}/out

UBOOT_DIR=$1
KERNEL_DIR=$2
BOOT_DIR=$3
ROOTFS_DIR=$4
PREBUILT=$5

KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"

# boot
rsync -a --no-o --no-g ${KERNEL_DIR}/${KIMG} ${BOOT_DIR}
rsync -a --no-o --no-g ${KERNEL_DIR}/${KDTB} ${BOOT_DIR}
rsync -a --no-o --no-g ${PREBUILT}/boot/* ${BOOT_DIR}

# rootfs
cp -af ${KMODULES_OUTDIR}/* ${ROOTFS_DIR}


exit 0
