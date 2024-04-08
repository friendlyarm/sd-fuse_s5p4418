#!/bin/bash
set -eu

function has_built_uboot() {
	if [ -f $1/bootloader.img ]; then
		echo 1
	else
		echo 0
	fi
}

function has_built_kernel() {
	local ARCH=arm
	local KIMG=arch/${ARCH}/boot/zImage
	if [ -f $1/${KIMG} ]; then
		echo 1
	else
		echo 0
	fi
}

function has_built_kernel_modules() {
	local OUTDIR=${2}
	local SOC=s5p4418
	if [ -d ${OUTDIR}/output_${SOC}_kmodules ]; then
		echo 1
	else
		echo 0
	fi
}

function check_and_install_package() {
	local PACKAGES=
	if ! command -v mkfs.exfat &>/dev/null; then
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			case "$VERSION_CODENAME" in
			jammy|bookworm|bullseye)
					PACKAGES="exfatprogs ${PACKAGES}"
					;;
			*)
					PACKAGES="exfat-fuse exfat-utils ${PACKAGES}"
					;;
			esac
		fi

	fi
	if ! [ -x "$(command -v simg2img)" ]; then
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			case "$VERSION_CODENAME" in
			focal|jammy|bookworm|bullseye)
					PACKAGES="android-sdk-libsparse-utils ${PACKAGES}"
					# PACKAGES="android-sdk-ext4-utils ${PACKAGES}"
					;;
			*)
					PACKAGES="android-tools-fsutils ${PACKAGES}"
					;;
			esac
		fi
	fi
	if ! [ -x "$(command -v swig)" ]; then
		PACKAGES="swig ${PACKAGES}"
	fi
	if ! [ -x "$(command -v git)" ]; then
		PACKAGES="git ${PACKAGES}"
	fi
	if ! [ -x "$(command -v wget)" ]; then
		PACKAGES="wget ${PACKAGES}"
	fi
	if ! [ -x "$(command -v rsync)" ]; then
		PACKAGES="rsync ${PACKAGES}"
	fi
	if ! command -v partprobe &>/dev/null; then
		PACKAGES="parted ${PACKAGES}"
	fi
	if ! command -v sfdisk &>/dev/null; then
		PACKAGES="fdisk ${PACKAGES}"
	fi
	if ! command -v resize2fs &>/dev/null; then
		PACKAGES="e2fsprogs ${PACKAGES}"
	fi
	if [ ! -z "${PACKAGES}" ]; then
		sudo apt install ${PACKAGES}
	fi
}

function check_and_install_toolchain() {
	case "$(uname -mpi)" in
	x86_64*)
		if [ ! -d /opt/FriendlyARM/toolchain/4.9.3 ]; then
			echo "please install arm-linux-gcc 4.9.3 first by running following commands: "
			echo "    git clone https://github.com/friendlyarm/prebuilts.git"
			echo "    sudo mkdir -p /opt/FriendlyARM/toolchain"
			echo "    (cd prebuilts/gcc-x64 && cat toolchain-4.9.3-armhf.tar.gz* | sudo tar xz -C /)"
			exit 1
		fi
		export PATH=/opt/FriendlyARM/toolchain/4.9.3/bin/:$PATH
		return 0
		;;
	*)
		echo "Error: cannot build armhf binary on this platform, only supports x86_64."
		;;
	esac
	return 1
}
