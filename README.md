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
git checkout master-for-linux-3.4.y
sudo ./fusing.sh /dev/sdX core-qte
```
You can build the following OS: core-qte, debian, debian-wifiap, eflasher, kitkat.  

Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called kernel-3.4-roms/images-for-eflasher, for example:
```
cd sd-fuse_s5p4418
tar xvzf ../images-for-eflasher/core-qte-images.tgz
sudo ./fusing.sh /dev/sdX core-qte
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
git checkout master-for-linux-3.4.y
wget http://112.124.9.243/dvdfiles/S5P4418/kernel-3.4-roms/images-for-eflasher/core-qte-images.tgz
tar xvzf core-qte-images.tgz
```
Now,  Change something under the core-qte directory, 
for example, replace the file you compiled, then build friendlycore bootable SD card: 
```
# sudo ./fusing.sh /dev/sde core-qte
```
or build an sd card image:
```
sudo ./mkimage.sh core-qte
```
The following file will be generated:  
```
s5p4418-ubuntu-core-qte-sd4g-$(date +%Y%m%d).img
```
You can use dd to burn this file into an sd card:
```
dd if=s5p4418-ubuntu-core-qte-sd4g-$(date +%Y%m%d).img of=/dev/sdX bs=1M
```

## Build a package similar to s5p4418-eflasher-sd8g-yyyymmdd-full.img:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
git checkout master-for-linux-3.4.y
sudo ./mkimage.sh eflasher
DEV=`losetup -f`
losetup ${DEV} s5p4418-eflasher-sd8g-20170819.img
partprobe ${DEV}
sudo mkfs.vfat ${DEV}p1 -n FRIENDLYARM
mkdir -p /mnt/fat
mount -t vfat ${DEV}p1 /mnt/fat
sudo wget -qO- http://112.124.9.243/dvdfiles/S5P4418/kernel-3.4-roms/images-for-eflasher/core-qte-images.tgz | tar xvz -C /mnt/fat --strip-components=1
umount /mnt/fat
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

### Build U-boot and Kernel for FriendlyCore
Download image files:
```
cd sd-fuse_s5p4418
git checkout master-for-linux-3.4.y
wget http://112.124.9.243/dvdfiles/S5P4418/kernel-3.4-roms/images-for-eflasher/core-qte-images.tgz
tar xzf core-qte-images.tgz
```
Build kernel 3.4:
```
cd sd-fuse_s5p4418
git clone https://github.com/friendlyarm/linux-3.4.y.git -b nanopi2-lollipop-mr1 --depth 1 linux
cd linux
touch .scmversion
export PATH=/opt/FriendlyARM/toolchain/4.9.3/bin:$PATH
make nanopi2_linux_defconfig
make uImage


# update boot.img
simg2img ../core-qte/boot.img ../core-qte/r.img
mkdir -p /mnt/core-qte-boot
mount -t ext4 -o loop ../core-qte/r.img /mnt/core-qte-boot
rm -rf /mnt/core-qte-boot/uImage*
cp arch/arm/boot/uImage /mnt/core-qte-boot/
cp arch/arm/boot/uImage /mnt/core-qte-boot/uImage.hdmi
../tools/make_ext4fs -s -l 67108864 -a root -L boot ../core-qte/boot.img /mnt/core-qte-boot
umount /mnt/core-qte-boot
rm ../core-qte/r.img
```
Build uboot:
```
cd sd-fuse_s5p4418
git checkout master-for-linux-3.4.y

git clone https://github.com/friendlyarm/uboot_nanopi2.git -b nanopi2-lollipop-mr1 --depth 1 u-boot
cd u-boot
make s5p4418_nanopi2_config
export PATH=/opt/FriendlyARM/toolchain/4.9.3/bin:$PATH
make CROSS_COMPILE=arm-linux-
cp u-boot.bin ../core-qte/bootloader
```

### Custom rootfs for FriendlyCore
#### Custom rootfs in the bootable SD card
Use FriendlyCore as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
git checkout master-for-linux-3.4.y
sudo ./mkimage.sh core-qte
DEV=`losetup -f`
losetup ${DEV} s5p4418-ubuntu-core-qte-sd4g-$(date +%Y%m%d).img
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
dd if=s5p4418-ubuntu-core-qte-sd4g-$(date +%Y%m%d).img of=/dev/sdX bs=1M
```
#### Custom rootfs for eMMC
Use FriendlyCore as an example, extract rootfs from rootfs.img:
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418.git
cd sd-fuse_s5p4418
git checkout master-for-linux-3.4.y
wget http://112.124.9.243/dvdfiles/S5P4418/kernel-3.4-roms/images-for-eflasher/core-qte-images.tgz
tar xzf core-qte-images.tgz
simg2img core-qte/rootfs.img core-qte/r.img
mkdir -p /mnt/rootfs
mount -t ext4 -o loop core-qte/r.img /mnt/rootfs
mkdir rootfs
cp -af /mnt/rootfs/* rootfs
umount /mnt/rootfs
rm core-qte/r.img
```
Now,  change something under rootfs directory, like this:
```
echo hello > rootfs/root/welcome.txt  
```
Remake rootfs.img  with the make_ext4fs utility:
```
./tools/make_ext4fs -s -l 3670016000 -a root -L rootfs rootfs.img rootfs
cp rootfs.img core-qte/
```
One thing you should be aware of is that the size of the .img file needs to be larger than the rootfs directory size, 
below are the image size values for each system we've provided:  
eflasher: 1604321280  
friendlycore: 3670016000   
 