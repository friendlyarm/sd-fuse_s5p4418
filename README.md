
# sd-fuse_s5p4418
## Introduction
This repository is a bunch of scripts to build bootable SD card images for FriendlyElec S5P4418 boards, the main features are as follows:

* Create root ﬁlesystem image from a directory
* Build bootable SD card image
* Easy way to compile kernel、uboot and third-party driver
  
*Read this in other languages: [简体中文](README_cn.md)*  
  
## Requirements
* Recommended Host OS: Ubuntu 20.04 LTS (Bionic Beaver) 64-bit or Higher
* It is recommended to run this script to initialize the development environment: https://github.com/friendlyarm/build-env-on-ubuntu-bionic
* Docker container: https://github.com/friendlyarm/docker-cross-compiler-novnc

## Kernel Version Support
The sd-fuse use multiple git branches to support each version of the kernel, the current branche supported kernel version is as follows:
* 4.4.y   
  
For other kernel versions, please switch to the related git branch.
## Target board OS Supported
*Notes: The OS name is the same as the directory name, it is written in the script so it cannot be renamed.*

* lubuntu
* friendlycore
* friendlycore-lite-focal
* android
* android7
* kitkat
* friendlywrt

  
To build an SD card image for friendlycore, for example like this:
```
./mk-sd-image.sh friendlycore
```
  
## Where to download files
The following files may be required to build SD card image:
* kernel source code: In the directory "07_Source codes" of [NetDrive](https://download.friendlyelec.com/s5p4418), or download from [Github](https://github.com/friendlyarm/linux), the branch name is nanopi2-v4.4.y
* uboot source code: In the directory "07_Source codes" of [NetDrive](https://download.friendlyelec.com/s5p4418), or download from [Github](https://github.com/friendlyarm/u-boot), the branch name is nanopi2-v2016.01
* pre-built partition image: In the directory "03_Partition image files" of [NetDrive](https://download.friendlyelec.com/s5p4418), or download from [HTTP server](http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher)
* compressed root file system tar ball: In the directory "06_File systems" of [NetDrive](https://download.friendlyelec.com/s5p4418), or download from [HTTP server](http://112.124.9.243/dvdfiles/s5p4418/rootfs)
  
If the files are not prepared in advance, the script will automatically download the required files, but the speed may be slower due to the bandwidth of the http server.

## Script Functions
* fusing.sh: Flash the image to SD card
* mk-sd-image.sh: Build SD card image
* mk-emmc-image.sh: Build SD-to-eMMC image, used to install system to eMMC

* build-boot-img.sh:  Create boot ﬁlesystem image(boot.img) from a directory

* build-rootfs-img.sh: Create root ﬁlesystem image(rootfs.img) from a directory
* build-kernel.sh: Compile the kernel, or kernel headers
* build-uboot.sh: Compile uboot

## Usage
### Build your own SD card image
*Note: Here we use friendlycore system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher), due to the bandwidth of the http server, we recommend downloading the file from the [NetDrive](https://download.friendlyelec.com/s5p4418):
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418 -b master --single-branch sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher/friendlycore-images.tgz
tar xvzf friendlycore-images.tgz
```
After decompressing, you will get a directory named friendlycore, you can change the files in the directory as needed, for example, replace rootfs.img with your own modified version, or your own compiled kernel and uboot, finally, flash the image to the SD card by entering the following command (The below steps assume your SD card is device /dev/sdX):
```
sudo ./fusing.sh /dev/sdX friendlycore
```
Or, package it as an SD card image file:
```
./mk-sd-image.sh friendlycore
```
The following flashable image file will be generated, it is now ready to be used to boot the device into friendlycore:  
```
out/s5p4418-sd-friendlycore-xenial-4.4-armhf-YYYYMMDD.img
```


### Build your own SD-to-eMMC Image
*Note: Here we use friendlycore system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher), here you need to download the friendlycore and eflasher [pre-built images](http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418 -b master --single-branch sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher/friendlycore-images.tgz
tar xvzf friendlycore-images.tgz
wget http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher/emmc-flasher-images.tgz
tar xvzf emmc-flasher-images.tgz
```
Then use the following command to build the SD-to-eMMC image, the autostart=yes parameter means it will automatically enter the flash process when booting:
```
./mk-emmc-image.sh friendlycore autostart=yes
```
The following flashable image file will be generated, ready to be used to boot the device into eflasher system and then flash friendlycore system to eMMC: 
```
out/s5p4418-eflasher-friendlycore-xenial-4.4-YYYYMMDD.img
```
### Backup rootfs and create custom SD image (to burn your application into other boards)
#### Backup rootfs
Run the following commands on your target board. These commands will back up the entire root partition:
```
sudo passwd root
su root
cd /
tar --warning=no-file-changed -cvpzf /rootfs.tar.gz \
    --exclude=/rootfs.tar.gz --exclude=/var/lib/docker/runtimes \
    --exclude=/etc/firstuser --exclude=/etc/friendlyelec-release \
    --exclude=/usr/local/first_boot_flag --one-file-system /
```
#### Making a bootable SD card from a root filesystem
*Note: Here we use friendlycore system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418 -b master --single-branch sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher/friendlycore-images.tgz
tar xvzf friendlycore-images.tgz
```
Extract the rootfs.tar.gz exported in the previous section, the tar command requires root privileges, so you need put sudo in front of the command:
```
mkdir friendlycore/rootfs
sudo tar xvzfp rootfs.tar.gz -C friendlycore/rootfs --numeric-owner --same-owner
```
or download the filesystem archive from the following URL and extract it:
```
wget http://112.124.9.243/dvdfiles/s5p4418/rootfs/rootfs-friendlycore.tgz
sudo tar xvzfp rootfs-friendlycore.tgz --numeric-owner --same-owner
```
Change something:
```
sudo sh -c 'echo hello > friendlycore/rootfs/root/welcome.txt'
```
Make rootfs to img:
```
sudo ./build-rootfs-img.sh friendlycore/rootfs friendlycore
```
Use the new rootfs.img to build SD card image:
```
./mk-sd-image.sh friendlycore
```
Or build SD-to-eMMC image:
```
./mk-emmc-image.sh friendlycore
```
If the image file is too large to be packaged, you can use an environment variable to reassign the image size, for example:
```
RAW_SIZE_MB=16000 ./mk-sd-image.sh friendlycore
RAW_SIZE_MB=16000 ./mk-emmc-image.sh friendlycore
```
### Compiling the Kernel
*Note: Here we use friendlycore system as an example*  
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher):
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418 -b master --single-branch sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher/friendlycore-images.tgz
tar xvzf friendlycore-images.tgz
```
Download the kernel source code from github, using the environment variable KERNEL_SRC to specify the local source code directory:
```
export KERNEL_SRC=$PWD/kernel
git clone https://github.com/friendlyarm/linux -b nanopi2-v4.4.y --depth 1 ${KERNEL_SRC}
```
Customize the kernel configuration:
```
cd $KERNEL_SRC
touch .scmversion
make ARCH=arm nanopi2_linux_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux- menuconfig
make ARCH=arm CROSS_COMPILE=arm-linux- savedefconfig
cp defconfig ./arch/arm/configs/my_defconfig                  # Save the configuration as my_defconfig
git add ./arch/arm/configs/my_defconfig
cd -
```
Specify the configuration of the kernel using the KCFG environment variable (KERNEL_SRC specifies the source directory), and compile the kernel with your configuration:
```
export KERNEL_SRC=$PWD/kernel
export KCFG=my_defconfig
./build-kernel.sh friendlycore
```

### Compiling the u-boot
*Note: Here we use friendlycore system as an example* 
Clone this repository locally, then download and uncompress the [pre-built images](http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher)::
```
git clone https://github.com/friendlyarm/sd-fuse_s5p4418 -b master --single-branch sd-fuse_s5p4418
cd sd-fuse_s5p4418
wget http://112.124.9.243/dvdfiles/s5p4418/images-for-eflasher/friendlycore-images.tgz
tar xvzf friendlycore-images.tgz
```
Download the u-boot source code from github that matches the OS version, the environment variable UBOOT_SRC is used to specify the local source code directory:
```
export UBOOT_SRC=$PWD/uboot
git clone https://github.com/friendlyarm/u-boot -b nanopi2-v2016.01 --depth 1 ${UBOOT_SRC}
./build-uboot.sh friendlycore
```

