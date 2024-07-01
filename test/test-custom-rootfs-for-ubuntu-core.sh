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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/ubuntu-noble-core-images.tgz
tar xzf ubuntu-noble-core-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/rootfs/rootfs-ubuntu-noble-core.tgz
tar xzf rootfs-ubuntu-noble-core.tgz
echo hello > ubuntu-noble-core/rootfs/root/welcome.txt
(cd ubuntu-noble-core/rootfs/root/ && {
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/ubuntu-noble-core-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh ubuntu-noble-core/rootfs ubuntu-noble-core
sudo ./mk-sd-image.sh ubuntu-noble-core
sudo ./mk-emmc-image.sh ubuntu-noble-core
