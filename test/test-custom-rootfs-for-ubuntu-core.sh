#!/bin/bash
set -eux

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/s5p4418/images
    ROOTFS_URL=http://cdn.local/friendlyelec-cdn/rootfs/s5p4418
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/s5p4418/images
    ROOTFS_URL=https://downloads.friendlyelec.com/rootfs/s5p4418
fi
# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget ${CDN_URL}/ubuntu-noble-core-images.tgz
tar xzf ubuntu-noble-core-images.tgz
wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget ${ROOTFS_URL}/rootfs-ubuntu-noble-core.tgz
wget ${ROOTFS_URL}/rootfs-ubuntu-noble-core.tgz.sha256
sha256sum -c rootfs-ubuntu-noble-core.tgz.sha256
tar xzf rootfs-ubuntu-noble-core.tgz
echo hello > ubuntu-noble-core/rootfs/root/welcome.txt
(cd ubuntu-noble-core/rootfs/root/ && {
	wget ${CDN_URL}/ubuntu-noble-core-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh ubuntu-noble-core/rootfs ubuntu-noble-core
sudo ./mk-sd-image.sh ubuntu-noble-core
sudo ./mk-emmc-image.sh ubuntu-noble-core
