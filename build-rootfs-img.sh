#!/bin/bash
set -eu

if [ $# -lt 2 ]; then
	echo "Usage: $0 <rootfs dir> <img filename> "
    echo "example:"
    echo "    tar xvzf NETDISK/S5P4418/rootfs/rootfs-friendlycore-20190603.tgz"
    echo "    ./build-rootfs-img.sh friendlycore/rootfs friendlycore"
	exit 0
fi

ROOTFS_DIR=$1
TARGET_OS=$2
IMG_FILE=$TARGET_OS/rootfs.img
if [ $# -eq 3 ]; then
	IMG_SIZE=$3
else
	IMG_SIZE=0
fi

TOP=$PWD
true ${MKFS:="${TOP}/tools/make_ext4fs"}

if [ ! -d ${ROOTFS_DIR} ]; then
    echo "path '${ROOTFS_DIR}' not found."
    exit 1
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
        echo "Re-running script under sudo..."
        sudo --preserve-env "$0" "$@"
        exit
fi

MKFS_OPTS="-s -a root -L rootfs"
if echo ${TARGET_OS} | grep friendlywrt -i >/dev/null; then
    # set default uid/gid to 0
    MKFS_OPTS="-0 ${MKFS_OPTS}"
fi

clean_rootfs() {
    (cd $1 && {
        # remove machine-id, the macaddress will be gen via it
        [ -f etc/machine-id ] && > etc/machine-id
        [ -f var/lib/dbus/machine-id ] && {
            rm -f var/lib/dbus/machine-id
            ln -s /etc/machine-id var/lib/dbus/machine-id
        }
        rm -f etc/friendlyelec-release
        rm -f root/running-state-file
        rm -f etc/firstuse
        rm -f var/lib/dpkg/lock
        rm -f var/lib/dpkg/lock-frontend
        rm -f var/cache/apt/archives/lock
        rm -f var/cache/apt/archives/*.deb
        cat /dev/null > etc/udev/rules.d/70-persistent-net.rules
        [ -d ./tmp ] && find ./tmp -exec rm -rf {} +
        mkdir -p ./tmp
        chmod 1777 ./tmp
        if [ -d ./var/lib/apt/lists ]; then
            PERM=`grep "^_apt" ./etc/passwd | cut -d':' -f3`
            if [ -e ./var/lib/apt/lists ]; then
                [ -z ${PERM} ] || chown -R ${PERM}.0 ./var/lib/apt/lists
            fi
            if [ -e ./var/cache/apt/archives/partial ]; then
                [ -z ${PERM} ] || chown -R ${PERM}.0 ./var/cache/apt/archives/partial
            fi
        fi
        find var/log -type f -delete
        find var/tmp -type f -delete
        find -name .bash_history -type f -exec cp /dev/null {} \;
        [ -e var/lib/systemd ] && touch var/lib/systemd/clock
        [ -e var/lib/private/systemd/timesync ] && touch var/lib/private/systemd/timesync/clock
        if [ -d var/lib/NetworkManager/ ]; then
            rm -fr var/lib/NetworkManager/dhclient*
            rm -fr var/lib/NetworkManager/secret_key
            rm -fr var/lib/NetworkManager/timestamps
        fi
        (cd dev && find . ! -type d -exec rm {} \;)
    })
}
clean_rootfs ${ROOTFS_DIR}

if [ ${IMG_SIZE} -eq 0 ]; then
    # calc image size
    ROOTFS_SIZE=`du -s -B 1 ${ROOTFS_DIR} | cut -f1`
    # +1024m + 10% rootfs size
    MAX_IMG_SIZE=$((${ROOTFS_SIZE} + 1024*1024*1024 + ${ROOTFS_SIZE}/10))
    TMPFILE=`tempfile`
    ${MKFS} -s -l ${MAX_IMG_SIZE} -a root -L rootfs /dev/null ${ROOTFS_DIR} > ${TMPFILE}
    IMG_SIZE=`cat ${TMPFILE} | grep "Suggest size:" | cut -f2 -d ':' | awk '{gsub(/^\s+|\s+$/, "");print}'`
    rm -f ${TMPFILE}

    if [ ${ROOTFS_SIZE} -gt ${IMG_SIZE} ]; then
            echo "IMG_SIZE less than ROOTFS_SIZE, why?"
            exit 1
    fi

    # make fs
    ${MKFS} ${MKFS_OPTS} -l ${IMG_SIZE} ${IMG_FILE} ${ROOTFS_DIR}
    if [ $? -ne 0 ]; then
            echo "error: failed to  make rootfs.img."
            exit 1
     fi
else
    ${MKFS} ${MKFS_OPTS} -l ${IMG_SIZE} ${IMG_FILE} ${ROOTFS_DIR}
    if [ $? -ne 0 ]; then
            echo "error: failed to  make rootfs.img."
            exit 1
     fi
fi

${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
echo "generating ${IMG_FILE} done."
echo 0


