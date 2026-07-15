#!/bin/bash
set -eux

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/s5p4418/images
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/s5p4418/images
fi
# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget ${CDN_URL}/friendlycore-images.tgz
tar xzf friendlycore-images.tgz
wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

# make big file
fallocate -l 6G friendlycore/rootfs.img

# calc image size
IMG_SIZE=`du -s -B 1 friendlycore/rootfs.img | cut -f1`

# re-gen partmap.txt
./tools/generate-partmap-txt.sh ${IMG_SIZE} friendlycore

sudo ./mk-sd-image.sh friendlycore
sudo ./mk-emmc-image.sh friendlycore
