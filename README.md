# sd-fuse_s5p4418
Create bootable SD card for NanoPi2/NanoPi Fire2A/NanoPi S2/NanoPi M2/NanoPC T2/Smart4418

## How to find the /dev name of my SD Card
Unplug all usb devices:
```
ls -1 /dev > ~/before.txt
```
plug it in, then
```
ls -1 /dev > ~/after.txt
diff ~/before.txt ~/after.txt
```

## Build friendlycore bootable SD card
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
sudo ./fusing.sh /dev/sdX friendlycore
```
You can build the following OS: friendlycore, lubuntu, eflasher, android, kitkat.  

Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called images-for-eflasher, for example:
```
cd sd-fuse_s5p4418
tar xvzf ../images-for-eflasher/friendlycore-images.tgz
sudo ./fusing.sh /dev/sdX friendlycore
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz
tar xvzf friendlycore-images.tgz
```
Now,  Change something under the friendlycore directory, 
for example, replace the file you compiled, then build friendlycore bootable SD card: 
```
sudo ./fusing.sh /dev/sdX friendlycore
```
or build an sd card image:
```
sudo ./mkimage.sh friendlycore
```
The following file will be generated:  
```
s5p4418-friendly-core-xenial-4.4-armhf-$(date +%Y%m%d).img
```
You can use dd to burn this file into an sd card:
```
dd if=s5p4418-friendly-core-xenial-4.4-armhf-20181227.img of=/dev/sdX bs=1M
```

## Build a package similar to s5p4418-eflasher-friendlycore-xenial-4.4-armhf-YYYYMMDD.img
Enable exFAT file system support on Ubuntu:
```
sudo apt-get install exfat-fuse exfat-utils
```
Generate the eflasher raw image, and put friendlycore image files into eflasher:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/S5P4418/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
sudo ./mkimage.sh eflasher
DEV=`losetup -f`
losetup ${DEV} s5p4418-eflasher-$(date +%Y%m%d).img
partprobe ${DEV}
sudo mkfs.exfat ${DEV}p1 -n FriendlyARM
mkdir -p /mnt/exfat
mount -t exfat ${DEV}p1 /mnt/exfat
wget http://112.124.9.243/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz -C /mnt/exfat
umount /mnt/exfat
losetup -d ${DEV}
```

## Replace the file you compiled

### Install cross compiler and tools

Install the package:
```
apt install liblz4-tool android-tools-fsutils
```
Install Cross Compiler:
```
git clone https://github.com/friendlyarm/prebuilts.git
sudo mkdir -p /opt/FriendlyARM/toolchain
sudo tar xf prebuilts/gcc-x64/arm-cortexa9-linux-gnueabihf-4.9.3.tar.xz -C /opt/FriendlyARM/toolchain/
```

### Build U-boot and Kernel for Lubuntu, FriendlyCore
Download image files:
```
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/S5P4418/images-for-eflasher/lubuntu-desktop-images.tgz
tar xzf lubuntu-desktop-images.tgz
wget http://112.124.9.243/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz
```
Build kernel:
```
cd sd-fuse_s5p4418
git clone https://github.com/friendlyarm/linux.git -b nanopi2-v4.4.y --depth 1
cd linux
touch .scmversion
export PATH=/opt/FriendlyARM/toolchain/4.9.3/bin:$PATH
make ARCH=arm nanopi2_linux_defconfig
make ARCH=arm
# lubuntu
simg2img ../lubuntu/boot.img ../lubuntu/r.img
mkdir -p /mnt/lubuntu-boot
mount -t ext4 -o loop ../lubuntu/r.img /mnt/lubuntu-boot
cp arch/arm/boot/zImage /mnt/lubuntu-boot
cp arch/arm/boot/dts/s5p4418-nanopi2-rev*.dtb /mnt/lubuntu-boot
umount /mnt/lubuntu-boot
rm ../lubuntu/r.img

# friendlycore
simg2img ../friendlycore/boot.img ../friendlycore/r.img
mkdir -p /mnt/friendlycore-boot
mount -t ext4 -o loop ../friendlycore/r.img /mnt/friendlycore-boot
cp arch/arm/boot/zImage /mnt/friendlycore-boot
cp arch/arm/boot/dts/s5p4418-nanopi2-rev*.dtb /mnt/friendlycore-boot
umount /mnt/friendlycore-boot
rm ../friendlycore/r.img
```
Build uboot:
```
cd sd-fuse_s5p4418
git clone https://github.com/friendlyarm/u-boot.git 
cd u-boot
git checkout nanopi2-v2016.01
make s5p4418_nanopi2_defconfig
export PATH=/opt/FriendlyARM/toolchain/4.9.3/bin:$PATH
make CROSS_COMPILE=arm-linux-
cp bootloader.img ../lubuntu/
cp bootloader.img ../friendlycore/
```

### Custom rootfs for Lubuntu, FriendlyCore
#### Custom rootfs in the bootable SD card
Use FriendlyCore as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
sudo ./mkimage.sh friendlycore
DEV=`losetup -f`
losetup ${DEV} s5p4418-friendly-core-xenial-4.4-armhf-$(date +%Y%m%d).img
partprobe ${DEV}
mkdir -p /mnt/rootfs
mount -t ext4 ${DEV}p2 /mnt/rootfs
```
Now,  Change something under /mnt/rootfs directory, like this:
```
echo hello > /mnt/rootfs/root/welcome.txt
```
Save and release resources:
```
umount /mnt/rootfs
losetup -d ${DEV}
```
burn to sd card:
```
dd if=s5p4418-friendly-core-xenial-4.4-armhf-$(date +%Y%m%d).img of=/dev/sdX bs=1M
```
#### Custom rootfs for eMMC
Use FriendlyCore as an example, extract rootfs from rootfs.img:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/S5P4418/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz
simg2img friendlycore/rootfs.img friendlycore/r.img
mkdir -p /mnt/rootfs
mount -t ext4 -o loop friendlycore/r.img /mnt/rootfs
mkdir rootfs
cp -af /mnt/rootfs/* rootfs
umount /mnt/rootfs
rm friendlycore/r.img
```
Now,  change something under rootfs directory, like this:
```
echo hello > rootfs/root/welcome.txt  
```
Remake rootfs.img  with the make_ext4fs utility:
```
./tools/make_ext4fs -s -l 5368709120 -a root -L rootfs rootfs.img rootfs
cp rootfs.img friendlycore/
```
One thing you should be aware of is that the size of the .img file needs to be larger than the rootfs directory size, 
below are the image size values for each system we've provided:  
eflasher: 1604321280  
friendlycore: 5368709120  
lubuntu: 5368709120  
  
### Build Android5
```
git clone https://gitlab.com/friendlyelec/s5pxx18-android5 android5-src
cd android5-src 
source build/envsetup.sh
lunch aosp_nanopi2-userdebug
make -j8
wget http://112.124.9.243/dvdfiles/S5P4418/images-for-eflasher/android-lollipop-images.tgz
tar xzf android-lollipop-images.tgz
cp out/target/product/nanopi2/boot.img \
    out/target/product/nanopi2/cache.img \
    out/target/product/nanopi2/userdata.img \
    out/target/product/nanopi2/system.img \
    out/target/product/nanopi2/partmap.txt \
    android/
```
Copy the new image files to the exfat partition of the eflasher sd card:
```
cp -af android /mnt/exfat/
```