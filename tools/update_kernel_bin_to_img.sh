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
KCFG=sunxi_defconfig
KIMG=arch/${ARCH}/boot/zImage
KDTB=arch/${ARCH}/boot/dts/s5p4418-nanopi2-*.dtb
KALL="zImage dtbs"
CROSS_COMPILER=arm-linux-

# ${OUT} ${KERNEL_SRC} ${TOPPATH}/${TARGET_OS} ${TOPPATH}/prebuilt
if [ $# -ne 4 ]; then
        echo "bug: missing arg, $0 needs four args"
        exit
fi
OUT=$1
KERNEL_BUILD_DIR=$2
TARGET_OS=$3
PREBUILT=$4
KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"

# copy kernel to boot.img
if [ -f ${TARGET_OS}/boot.img ]; then
    echo "copying kernel to boot.img ..."
    simg2img ${TARGET_OS}/boot.img ${TARGET_OS}/r.img
    mkdir -p ${OUT}/old_boot
    mount -t ext4 -o loop ${TARGET_OS}/r.img ${OUT}/old_boot
    mkdir -p ${OUT}/boot
    rm -rf ${OUT}/boot/*
    cp -af ${OUT}/old_boot/* ${OUT}/boot
    umount ${OUT}/old_boot
    rm ${TARGET_OS}/r.img
    rm -rf ${OUT}/old_boot

    cp ${KERNEL_BUILD_DIR}/${KIMG} ${OUT}/boot/
    cp -avf ${KERNEL_BUILD_DIR}/${KDTB} ${OUT}/boot/

    ./build-boot-img.sh ${OUT}/boot ${TARGET_OS}/boot.img
    if [ $? -ne 0 ]; then
        echo "failed to update kernel to boot.img."
        exit 1
    fi
else 
	echo "not found ${TARGET_OS}/boot.img"
	exit 1
fi

# copy kernel modules to rootfs.img
if [ -f ${TARGET_OS}/rootfs.img ]; then
    echo "copying kernel module and firmware to rootfs ..."

    simg2img ${TARGET_OS}/rootfs.img ${TARGET_OS}/r.img
    mkdir -p ${OUT}/old_rootfs
    mount -t ext4 -o loop ${TARGET_OS}/r.img ${OUT}/old_rootfs
    mkdir -p ${OUT}/rootfs
    rm -rf ${OUT}/rootfs/*
    cp -af ${OUT}/old_rootfs/* ${OUT}/rootfs
    umount ${OUT}/old_rootfs
    rm ${TARGET_OS}/r.img
    rm -rf ${OUT}/old_rootfs

    cp -af ${KMODULES_OUTDIR}/lib/firmware/* ${OUT}/rootfs/lib/firmware/
    rm -rf ${OUT}/rootfs/lib/modules/*
    cp -af ${KMODULES_OUTDIR}/lib/modules/* ${OUT}/rootfs/lib/modules/

    ./build-rootfs-img.sh ${OUT}/rootfs ${TARGET_OS}/rootfs.img
    if [ $? -ne 0 ]; then
        echo "failed to update kernel-modules to rootfs.img."
        exit 1
    fi
else 
	echo "not found ${TARGET_OS}/rootfs.img"
	exit 1
fi


