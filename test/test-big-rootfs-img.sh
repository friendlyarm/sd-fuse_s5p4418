#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/s5p4418/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/s5p4418/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

# make big file
fallocate -l 6G friendlycore/rootfs.img

# calc image size
IMG_SIZE=`du -s -B 1 friendlycore/rootfs.img | cut -f1`

# re-gen partmap.txt
./tools/generate-partmap-txt.sh ${IMG_SIZE} friendlycore

sudo ./mk-sd-image.sh friendlycore
sudo ./mk-emmc-image.sh friendlycore
