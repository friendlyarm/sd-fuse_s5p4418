#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243
KERNEL_URL=https://github.com/friendlyarm/linux
KERNEL_BRANCH=nanopi2-v4.4.y

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

git clone ${KERNEL_URL} -b ${KERNEL_BRANCH} --depth 1 kernel-s5p4418
# disable framebuffer console support, keep logo on for a longer time
sed -i -e 's/CONFIG_FRAMEBUFFER_CONSOLE=y/CONFIG_FRAMEBUFFER_CONSOLE=n/g' kernel-s5p4418/arch/arm/configs/nanopi2_linux_defconfig
LOGO=$PWD/test/files/logo.bmp KERNEL_SRC=$PWD/kernel-s5p4418 ./build-kernel.sh friendlycore
LOGO=$PWD/test/files/logo.bmp KERNEL_SRC=$PWD/kernel-s5p4418 ./build-kernel.sh eflasher
sudo ./mk-sd-image.sh friendlycore
sudo ./mk-emmc-image.sh friendlycore
