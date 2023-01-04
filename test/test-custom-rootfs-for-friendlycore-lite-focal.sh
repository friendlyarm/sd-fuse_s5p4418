#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
       HTTP_SERVER=127.0.0.1
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-lite-focal-images.tgz
tar xzf friendlycore-lite-focal-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/rootfs/rootfs-friendlycore-lite-focal.tgz
tar xzf rootfs-friendlycore-lite-focal.tgz
echo hello > friendlycore-lite-focal/rootfs/root/welcome.txt
(cd friendlycore-lite-focal/rootfs/root/ && {
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-lite-focal-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore-lite-focal/rootfs friendlycore-lite-focal
sudo ./mk-sd-image.sh friendlycore-lite-focal
sudo ./mk-emmc-image.sh friendlycore-lite-focal
