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

UBOOT_REPO=https://github.com/friendlyarm/u-boot
UBOOT_BRANCH=nanopi2-v2016.01

ARCH=arm
UCFG=s5p4418_nanopi2_defconfig
CROSS_COMPILE=arm-linux-

TOPPATH=$PWD
OUT=$TOPPATH/out
if [ ! -d $OUT ]; then
	echo "path not found: $OUT"
	exit 1
fi
true ${uboot_src:=${OUT}/uboot-${SOC}}
true ${UBOOT_SRC:=${uboot_src}}

function usage() {
       echo "Usage: $0 <friendlycore|friendlycore-lite-noble|friendlywrt>"
       echo "# example:"
       echo "# clone uboot source from github:"
       echo "    git clone ${UBOOT_REPO} --depth 1 -b ${UBOOT_BRANCH} ${UBOOT_SRC}"
       echo "# or clone your local repo:"
       echo "    git clone git@192.168.1.2:/path/to/uboot.git --depth 1 -b ${UBOOT_BRANCH} ${UBOOT_SRC}"
       echo "# then"
       echo "    ./build-uboot.sh friendlycore "
       echo "    ./mk-emmc-image.sh friendlycore "
       echo "# also can do:"
       echo "	UBOOT_SRC=~/myuboot ./build-uboot.sh friendlycore"
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
if ! [ -x "$(command -v python2)" ]; then
	sudo apt install python2
fi
if ! [ -x "$(command -v python)" ]; then
    (cd /usr/bin/ && sudo ln -s python2 python)
fi
# get include path for this python version
INCLUDE_PY=$(python -c "import sysconfig as s; print(s.get_config_vars()['INCLUDEPY'])")
if [ ! -f "${INCLUDE_PY}/Python.h" ]; then
    sudo apt install python2-dev
fi

# ----------------------------------------------------------
# Get target OS
true ${TARGET_OS:=$(echo ${1,,}|sed 's/\///g')}
PARTMAP=./${TARGET_OS}/partmap.txt

case ${TARGET_OS} in
friendlycore* | friendlywrt | eflasher)
        ;;
*)
        echo "Error: Unsupported target OS: ${TARGET_OS}"
        exit 0
esac

download_img() {
    if [ ! -f ${PARTMAP} ]; then
	ROMFILE=`./tools/get_pkg_filename.sh ${1}`
        cat << EOF
Warn: Image not found for "${1}"
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
        ./tools/get_rom.sh "${1}" || exit 1
    fi
}

if [ ! -d ${UBOOT_SRC} ]; then
	git clone ${UBOOT_REPO} --depth 1 -b ${UBOOT_BRANCH} ${UBOOT_SRC}
fi

cd ${UBOOT_SRC}
make distclean
make ${UCFG} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)

if [ $? -ne 0 ]; then
	echo "failed to build uboot."
	exit 1
fi

if [ x"$DISABLE_MKIMG" = x"1" ]; then
    exit 0
fi

echo "building uboot ok."
cd ${TOPPATH}
download_img ${TARGET_OS}
./tools/update_uboot_bin.sh ${UBOOT_SRC} ${TOPPATH}/${TARGET_OS}
if [ $? -eq 0 ]; then
    echo "updating ${TARGET_OS}/bootloader.img ok."
else
    echo "failed."
    exit 1
fi

exit 0
