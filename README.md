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
You can build the following OS: friendlycore, lubuntu, eflasher, android7, android, kitkat.  

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
sudo ./mk-sd-image.sh friendlycore
```
The following file will be generated:  
```
s5p4418-friendly-core-xenial-4.4-armhf-$(date +%Y%m%d).img
```
You can use dd to burn this file into an sd card:
```
dd if=s5p4418-friendly-core-xenial-4.4-armhf-$(date +%Y%m%d).img of=/dev/sdX bs=1M
```

## Build an sdcard-to-emmc image (eflasher rom)
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
sudo ./mk-emmc-image.sh friendlycore
```
The following file will be generated:  
```
out/s5p4418-eflasher-friendlycore-bionic-4.4-yyyymmdd.img
```
You can use dd to burn this file into an sd card:
```
dd if=out/out/s5p4418-eflasher-friendlycore-bionic-4.4-yyyymmdd.img of=/dev/sdX bs=1M
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
git clone https://github.com/friendlyarm/linux.git -b nanopi2-v4.4.y --depth 1 out/kernel-s5p4418

# lubuntu
./build-kernel.sh lubuntu

# friendlycore
./build-kernel.sh friendlycore
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

### Custom rootfs for FriendlyCore
Use FriendlyCore as an example, extract rootfs from rootfs.img:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/S5P4418/rootfs/rootfs-friendlycore-YYMMDD.tgz
tar xzf rootfs-friendlycore-YYMMDD.tgz
```
Now,  change something under rootfs directory, like this:
```
echo hello > friendlycore/rootfs/root/welcome.txt  
```
Remake rootfs.img:
```
./build-rootfs-img.sh friendlycore/rootfs friendlycore
```
Make sdboot image:
```
sudo ./mk-sd-image.sh friendlycore
```
or make sd-to-emmc image (eflasher rom):
```
sudo ./mk-emmc-image.sh friendlycore
```
  
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
