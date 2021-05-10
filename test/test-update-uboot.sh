#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
       HTTP_SERVER=192.168.1.9
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz

git clone https://github.com/friendlyarm/u-boot --depth 1 -b nanopi2-v2016.01 uboot-s5p4418

UBOOT_SRC=$PWD/uboot-s5p4418 ./build-uboot.sh friendlycore
sudo ./mk-sd-image.sh friendlycore
