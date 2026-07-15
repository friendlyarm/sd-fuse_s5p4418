#!/bin/bash
set -eu

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/s5p4418/images
    ROOTFS_URL=http://cdn.local/friendlyelec-cdn/rootfs/s5p4418
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/s5p4418/images
    ROOTFS_URL=https://downloads.friendlyelec.com/rootfs/s5p4418
fi
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
wget ${CDN_URL}/friendlycore-images.tgz
tar xzf friendlycore-images.tgz
wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget ${ROOTFS_URL}/rootfs-friendlycore.tgz
wget ${ROOTFS_URL}/rootfs-friendlycore.tgz.sha256
sha256sum -c rootfs-friendlycore.tgz.sha256
tar xzf rootfs-friendlycore.tgz

# custome rootfs: re-gen rootfs.img
echo hello > friendlycore/rootfs/root/welcome.txt
(cd friendlycore/rootfs/root/ && {
	wget ${CDN_URL}/friendlycore-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore/rootfs friendlycore

# custome logo: re-gen boot.img
wget https://upload.wikimedia.org/wikipedia/commons/8/8d/Linux_Logo.jpg
convert Linux_Logo.jpg -type truecolor friendlycore/boot/logo.bmp
./build-boot-img.sh friendlycore/boot friendlycore/boot.img

# custome kernel
git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-s5p4418
(cd kernel-s5p4418 && {
	# disabling "Framebuffer Console support" allows Logo to stay long enough until user-app starts.
	sed -i 's/^CONFIG_FRAMEBUFFER_CONSOLE=.*/# CONFIG_FRAMEBUFFER_CONSOLE is not set/' arch/arm/configs/nanopi2_linux_defconfig
})
KERNEL_SRC=$PWD/kernel-s5p4418 ./build-kernel.sh friendlycore

sudo ./mk-sd-image.sh friendlycore
sudo ./mk-emmc-image.sh friendlycore
