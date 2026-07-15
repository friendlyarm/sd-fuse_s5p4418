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
git clone ../../.git sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget ${CDN_URL}/friendlycore-images.tgz
tar xzf friendlycore-images.tgz

# git clone https://github.com/friendlyarm/linux -b nanopi2-v4.4.y --depth 1 kernel-s5p4418
git clone git@192.168.1.5:/devel/kernel/linux.git --depth 1 -b nanopi2-v4.4.y kernel-s5p4418

KERNEL_SRC=$PWD/kernel-s5p4418 ./build-kernel.sh friendlycore
sudo ./mk-sd-image.sh friendlycore
