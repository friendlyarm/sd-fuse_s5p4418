#!/bin/bash

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

# ----------------------------------------------------------
# base setup

BASE_URL=http://112.124.9.243/dvdfiles
BOARD=NanoPi2

TARGET=${1,,}

case ${TARGET} in
android)
	ROMFILE=android-kitkat-images.tgz;;
debian)
	ROMFILE=debian-jessie-images.tgz;;
*)
	echo "Usage: $0 <android|debian>"
	exit 1
esac

#----------------------------------------------------------
# local functions

function FA_DoExec() {
	echo "> ${@}"
	eval $@
}

function download_file()
{
	local url=${BASE_URL}/${BOARD}/$1

	if [ -z $1 ]; then
		echo "Error downloading file: $1"
		exit 1
	fi

	if [ -f $1 ]; then
		rm -fv $1
	fi

	FA_DoExec wget ${url}
	if [[ "$?" != 0 ]]; then
		echo "Error downloading file: $1"
		exit 1
	fi

	return 0
}

#----------------------------------------------------------
# download image and verify it

download_file ${ROMFILE}
download_file ${ROMFILE}.hash.md5

FA_DoExec md5sum -c ${ROMFILE}.hash.md5
if [[ "$?" != 0 ]]; then
	echo "Error in downloaded file, please try again, or download it by"
	echo "bowser or other tools, URL is:"
	echo "  ${BASE_URL}/${BOARD}/${ROMFILE}"
	echo "  ${BASE_URL}/${BOARD}/${ROMFILE}.hash.md5"
	exit 1
fi

#----------------------------------------------------------
# extract

mkdir -p ${TARGET}

if [ -f ${ROMFILE} ]; then
	tar xzvf ${ROMFILE} -C ${TARGET}
fi

