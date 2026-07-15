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
git clone ../../.git -b master sd-fuse_s5p4418
cd sd-fuse_s5p4418

wget ${CDN_URL}/friendlycore-images.tgz
tar xzf friendlycore-images.tgz

wget ${CDN_URL}/ubuntu-noble-core-images.tgz
tar xzf ubuntu-noble-core-images.tgz

wget ${CDN_URL}/friendlywrt-images.tgz
tar xzf friendlywrt-images.tgz

wget ${CDN_URL}/lubuntu-desktop-images.tgz
tar xzf lubuntu-desktop-images.tgz

wget ${CDN_URL}/android-nougat-images.tgz
tar xzf android-nougat-images.tgz

wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

sudo ./mk-sd-image.sh friendlycore
sudo ./mk-emmc-image.sh friendlycore

sudo ./mk-sd-image.sh ubuntu-noble-core
sudo ./mk-emmc-image.sh ubuntu-noble-core

sudo ./mk-sd-image.sh friendlywrt
sudo ./mk-emmc-image.sh friendlywrt

# sudo ./mk-sd-image.sh android7
sudo ./mk-emmc-image.sh android7

sudo ./mk-sd-image.sh lubuntu
sudo ./mk-emmc-image.sh lubuntu

echo "done."
