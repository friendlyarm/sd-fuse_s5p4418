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

# git clone https://github.com/friendlyarm/linux -b nanopi2-v4.4.y --depth 1 kernel-s5p4418
git clone git@192.168.1.5:/devel/kernel/linux.git --depth 1 -b nanopi2-v4.4.y kernel-s5p4418

KERNEL_SRC=$PWD/kernel-s5p4418 ./build-kernel.sh friendlycore
sudo ./mk-sd-image.sh friendlycore
