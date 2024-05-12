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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/rootfs/rootfs-eflasher.tgz
tar xzf rootfs-eflasher.tgz

echo hello > eflasher/rootfs/root/welcome.txt
(cd eflasher/rootfs/root/ && {
    wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz -O deleteme.tgz
});

./build-rootfs-img.sh eflasher/rootfs eflasher
sudo ./mk-emmc-image.sh friendlycore
