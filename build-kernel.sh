#!/bin/bash
set -eu

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

true ${SOC:=s5p4418}
true ${DISABLE_MKIMG:=0}
true ${SKIP_DISTCLEAN:=0}
true ${LOGO:=}
true ${TARGET_OS:=$(echo ${1,,}|sed 's/\///g')}

KERNEL_REPO=https://github.com/friendlyarm/linux
KERNEL_BRANCH=nanopi2-v4.4.y

ARCH=arm
true ${KCFG:=nanopi2_linux_defconfig}
KIMG=arch/${ARCH}/boot/zImage
KDTB=arch/${ARCH}/boot/dts/s5p4418-nanopi2-*.dtb
KALL=
CROSS_COMPILE=arm-linux-

# 
# kernel logo:
# 
# convert logo.jpg -type truecolor /tmp/logo.bmp 
# convert logo.jpg -type truecolor /tmp/logo_kernel.bmp
# LOGO=/tmp/logo.bmp
# KERNEL_LOGO=/tmp/logo_kernel.bmp
#

TOPPATH=$PWD
OUT=$TOPPATH/out
if [ ! -d $OUT ]; then
	echo "path not found: $OUT"
	exit 1
fi
KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"
true ${kernel_src:=out/kernel-${SOC}}
true ${KERNEL_SRC:=$(readlink -f ${kernel_src})}

function usage() {
       echo "Usage: $0 <img dir>"
       echo "# example:"
       echo "# clone kernel source from github:"
       echo "    git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} ${kernel_src}"
       echo "# or clone your local repo:"
       echo "    git clone git@192.168.1.2:/path/to/linux.git --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_SRC}"
       echo "# then"
       echo "    LOGO=/tmp/logo.bmp ./build-kernel.sh friendlycore"
       echo "    LOGO=/tmp/logo.bmp ./build-kernel.sh eflasher"
       echo "    ./mk-emmc-image.sh friendlycore"
       echo "# also can do:"
       echo "    KERNEL_SRC=~/mykernel ./build-kernel.sh friendlycore"
       exit 0
}

if [ $# -ne 1 ]; then
    usage
fi

. ${TOPPATH}/tools/util.sh
check_and_install_toolchain
if [ $? -ne 0 ]; then
    exit 1
fi
check_and_install_package

PARTMAP=./${TARGET_OS}/partmap.txt
case ${TARGET_OS} in
friendlycore* | ubuntu-*-core | lubuntu* | friendlywrt | eflasher)
        ;;
*)
        echo "Error: Unsupported target OS: ${TARGET_OS}"
        exit 1
esac

download_img() {
    if [ ! -f ${PARTMAP} ]; then
	ROMFILE=`./tools/get_pkg_filename.sh ${1}`
        cat << EOF
Warn: Image not found for ${1}
----------------
you may download it from the netdisk (dl.friendlyarm.com) to get a higher downloading speed,
the image files are stored in a directory called "03_Partition image files", for example:
    tar xvzf /path/to/NetDrive/03_Partition\ image\ files/${ROMFILE}
----------------
Do you want to download it now via http? (Y/N):
EOF
        while read -r -n 1 -t 3600 -s USER_REPLY; do
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
        ./tools/get_rom.sh ${1} || exit 1
    fi
}

if [ ! -d ${KERNEL_SRC} ]; then
	git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_SRC}
fi

echo "kernel src: ${KERNEL_SRC}"
if [ -f "${LOGO}" ]; then
	cp -f ${LOGO} ${KERNEL_SRC}/logo.bmp
	echo "using ${LOGO} as logo."
else
	echo "using official logo."
fi

cd ${KERNEL_SRC}
if [ ${SKIP_DISTCLEAN} -ne 1 ]; then
	make ARCH=${ARCH} distclean
fi
touch .scmversion
make ARCH=${ARCH} ${KCFG}
if [ $? -ne 0 ]; then
	echo "failed to build kernel."
	exit 1
fi
if [ x"${TARGET_OS}" = x"eflasher" ]; then
    cp -avf .config .config.old
    sed -i "s/.*\(PROT_MT_SYNC\).*/CONFIG_TOUCHSCREEN_\1=y/g" .config
    sed -i "s/\(.*PROT_MT_SLOT\).*/# \1 is not set/g" .config
fi

make ARCH=${ARCH} ${KALL} -j$(nproc)
if [ $? -ne 0 ]; then
        echo "failed to build kernel."
        exit 1
fi

rm -rf ${KMODULES_OUTDIR}
mkdir -p ${KMODULES_OUTDIR}
make ARCH=${ARCH} INSTALL_MOD_PATH=${KMODULES_OUTDIR} modules -j$(nproc)
if [ $? -ne 0 ]; then
	echo "failed to build kernel modules."
        exit 1
fi
make ARCH=${ARCH} INSTALL_MOD_PATH=${KMODULES_OUTDIR} modules_install
if [ $? -ne 0 ]; then
	echo "failed to build kernel modules."
        exit 1
fi
(cd ${KMODULES_OUTDIR} && find . -name \*.ko | xargs ${CROSS_COMPILE}strip --strip-unneeded)

if [ ! -d ${KMODULES_OUTDIR}/lib ]; then
	echo "not found kernel modules."
	exit 1
fi

if [ x"$DISABLE_MKIMG" = x"1" ]; then
    exit 0
fi

echo "building kernel ok."

cd ${TOPPATH}
download_img ${TARGET_OS}
LOGO=${LOGO} KCFG=${KCFG} ./tools/update_kernel_bin_to_img.sh ${OUT} ${KERNEL_SRC} ${TARGET_OS} ${TOPPATH}/prebuilt

if [ $? -eq 0 ]; then
    echo "updating kernel ok."
else
    echo "failed."
    exit 1
fi
