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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-lite-noble-images.tgz
tar xzf friendlycore-lite-noble-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/rootfs/rootfs-friendlycore-lite-noble.tgz
tar xzf rootfs-friendlycore-lite-noble.tgz
echo hello > friendlycore-lite-noble/rootfs/root/welcome.txt
(cd friendlycore-lite-noble/rootfs/root/ && {
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-lite-noble-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore-lite-noble/rootfs friendlycore-lite-noble
sudo ./mk-sd-image.sh friendlycore-lite-noble
sudo ./mk-emmc-image.sh friendlycore-lite-noble
