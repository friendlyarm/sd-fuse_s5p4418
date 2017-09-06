# sd-fuse_nanopi2
Create bootable SD card for NanoPi2/NanoPi2 Fire/NanoPi M2/NanoPC T2/Smart4418

# Build a package similar to s5p4418-eflasher-sd8g-yyyymmdd-full.img:
```
# git clone https://github.com/friendlyarm/sd-fuse_nanopi2.git
# cd sd-fuse_nanopi2
# sudo ./mkimage.sh eflasher
# DEV=`losetup -f`
# losetup ${DEV} s5p4418-eflasher-sd8g-20170819.img
# partprobe ${DEV}
# sudo mkfs.vfat ${DEV}p1 -n FRIENDLYARM
# mkdir -p /mnt/fat
# mount -t vfat ${DEV}p1 /mnt/fat
# sudo wget -qO- http://112.124.9.243/dvdfiles/S5P4418/images-for-eflasher/core-qte-images.tgz | tar xvz -C /mnt/fat --strip-components=1
# umount /mnt/fat
# losetup -d ${DEV}
```

# Build android bootable SD card
```
# git clone https://github.com/friendlyarm/sd-fuse_nanopi2.git
# cd sd-fuse_nanopi2
# sudo ./mkimage.sh android /dev/sde
```
