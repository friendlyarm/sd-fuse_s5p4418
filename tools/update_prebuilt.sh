#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

# use partmap.txt, partmap_sd.txt only for fastboot
cp -f $2/partmap.txt $1/
cp -f $2/bl1-mmcboot.bin $1/
cp -f $2/loader-mmc.img $1/
cp -f $2/bl_mon.img $1

USERDATA_SIZE=104857600
echo "Generating empty userdata.img (size:${USERDATA_SIZE})"
TMPDIR=`mktemp -d`
${PWD}/tools/make_ext4fs -s -l ${USERDATA_SIZE} -a root -L userdata $1/userdata.img ${TMPDIR}
rm -rf ${TMPDIR}

exit $?
