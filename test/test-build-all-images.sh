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
git clone ../../.git -b master sd-fuse_s5p4418
cd sd-fuse_s5p4418

wget http://${HTTP_SERVER}/dvdfiles/s5p4418/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/s5p4418/images-for-eflasher/friendlycore-lite-focal-images.tgz
tar xzf friendlycore-lite-focal-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/s5p4418/images-for-eflasher/friendlywrt-images.tgz
tar xzf friendlywrt-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/s5p4418/images-for-eflasher/lubuntu-desktop-images.tgz
tar xzf lubuntu-desktop-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/s5p4418/images-for-eflasher/android-nougat-images.tgz
tar xzf android-nougat-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/s5p4418/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

sudo ./mk-sd-image.sh friendlycore
sudo ./mk-emmc-image.sh friendlycore

sudo ./mk-sd-image.sh friendlycore-lite-focal
sudo ./mk-emmc-image.sh friendlycore-lite-focal

sudo ./mk-sd-image.sh friendlywrt
sudo ./mk-emmc-image.sh friendlywrt

# sudo ./mk-sd-image.sh android7
sudo ./mk-emmc-image.sh android7

sudo ./mk-sd-image.sh lubuntu
sudo ./mk-emmc-image.sh lubuntu

echo "done."
