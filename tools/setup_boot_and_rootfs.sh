#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

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
TARGET_OS=$6

KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"

# boot
rsync -a --no-o --no-g ${KERNEL_DIR}/${KIMG} ${BOOT_DIR}
rsync -a --no-o --no-g ${KERNEL_DIR}/${KDTB} ${BOOT_DIR}
rsync -a --no-o --no-g ${PREBUILT}/boot/* ${BOOT_DIR}
rsync -a --no-o --no-g ${PREBUILT}/ramdisk.img ${BOOT_DIR}

# rootfs
rm -rf ${ROOTFS_DIR}/lib/modules/*
cp -af ${KMODULES_OUTDIR}/* ${ROOTFS_DIR}

# firmware
if [ ! -d ${ROOTFS_DIR}/lib/firmware/ap6212 ]; then
        tar xzf ${PREBUILT}/firmware/lib.tgz -C ${ROOTFS_DIR}/
fi

exit 0
