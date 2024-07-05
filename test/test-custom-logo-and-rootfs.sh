#!/bin/bash
set -eu

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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/rootfs/rootfs-friendlycore.tgz
tar xzf rootfs-friendlycore.tgz

# custome rootfs: re-gen rootfs.img
echo hello > friendlycore/rootfs/root/welcome.txt
(cd friendlycore/rootfs/root/ && {
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz -O deleteme.tgz
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
