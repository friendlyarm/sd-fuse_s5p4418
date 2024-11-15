#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
    echo "Re-running script under sudo..."
    sudo --preserve-env "$0" "$@"
    exit
fi

TOP=$PWD
true ${LOGO:=}
HOST_ARCH=
if uname -mpi | grep aarch64 >/dev/null; then
    HOST_ARCH="aarch64/"
fi

export MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf"
if [ ! -f ${MKE2FS_CONFIG} ]; then
    echo "error: ${MKE2FS_CONFIG} not found."
    exit 1
fi
true ${MKFS:="${TOP}/tools/${HOST_ARCH}mke2fs"}

true ${SOC:=s5p4418}
ARCH=arm
KIMG=arch/${ARCH}/boot/zImage
KDTB=arch/${ARCH}/boot/dts/s5p4418-nanopi2-*.dtb
KALL="zImage dtbs"
CROSS_COMPILE=arm-linux-
# ${OUT} ${KERNEL_SRC} ${TOPPATH}/${TARGET_OS} ${TOPPATH}/prebuilt
if [ $# -ne 4 ]; then
        echo "bug: missing arg, $0 needs four args"
        exit
fi
OUT=$1
KERNEL_BUILD_DIR=$2
TARGET_OS=$(echo ${3,,}|sed 's/\///g')
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
	
	if [ -f "${LOGO}" ]; then
		cp -avf ${LOGO} ${OUT}/boot/
	fi

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

    # Extract rootfs from img
    simg2img ${TARGET_OS}/rootfs.img ${TARGET_OS}/r.img
    mkdir -p ${OUT}/rootfs_mnt
    mkdir -p ${OUT}/rootfs_new
    mount -t ext4 -o loop ${TARGET_OS}/r.img ${OUT}/rootfs_mnt
    if [ $? -ne 0 ]; then
        echo "failed to mount ${TARGET_OS}/r.img."
        exit 1
    fi
    rm -rf ${OUT}/rootfs_new/*
    cp -af ${OUT}/rootfs_mnt/* ${OUT}/rootfs_new/
    umount ${OUT}/rootfs_mnt
    rm -rf ${OUT}/rootfs_mnt
    rm -f ${TARGET_OS}/r.img

    # Processing rootfs_new
    # Here s5pxx18 is different from h3/h5
	
    cp -af ${KMODULES_OUTDIR}/lib/firmware/* ${OUT}/rootfs_new/lib/firmware/
    rm -rf ${OUT}/rootfs_new/lib/modules/*
    cp -af ${KMODULES_OUTDIR}/lib/modules/* ${OUT}/rootfs_new/lib/modules/
	
    MKFS_OPTS="-E android_sparse -t ext4 -L rootfs -M /root -b 4096"
    case ${TARGET_OS} in
    friendlywrt* | buildroot*)
        # set default uid/gid to 0
        MKFS_OPTS="-0 ${MKFS_OPTS}"
        ;;
    *)
        ;;
    esac

    # Make rootfs.img
    ROOTFS_DIR=${OUT}/rootfs_new
    # clean device files
    (cd ${ROOTFS_DIR}/dev && find . ! -type d -exec rm {} \;)
    # calc image size
    IMG_SIZE=$(((`du -s -B64M ${ROOTFS_DIR} | cut -f1` + 3) * 1024 * 1024 * 64))
    IMG_BLK=$((${IMG_SIZE} / 4096))
    INODE_SIZE=$((`find ${ROOTFS_DIR} | wc -l` + 128))
    # make fs
    [ -f ${TARGET_OS}/rootfs.img ] && rm -f ${TARGET_OS}/rootfs.img
    ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${ROOTFS_DIR} ${TARGET_OS}/rootfs.img ${IMG_BLK}

    echo "IMG_SIZE=${IMG_SIZE}" > ${OUT}/${TARGET_OS}_rootfs-img.info
    ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
else 
	echo "not found ${TARGET_OS}/rootfs.img"
	exit 1
fi
