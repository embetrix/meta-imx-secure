#!/usr/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# imx secure initramfs init script:
#   mount_early_fs         - Mount devtmpfs, tmpfs, proc, sysfs, securityfs
#   setup_slot_devices     - Select slot devices from the kernel command line
#   setup_encrypted_rootfs - Prepare and verify the encrypted root filesystem
#   mount_dmcrypt_data     - First-boot data partitions encryption
#   setup_evm_integrity    - Setup EVM mode
#   switch_root            - Switch to the real root filesystem
#

#set -x
umask 077
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

BOOT_DEV=""
BOOTUPDATE_DEV=""
SECDATA_DEV=""
ROOT_DEV=""
UPDATE_DEV=""
DATA_DEV=""

ROOT_DM_NAME="root"
UPDATE_DM_NAME="update"
DATA_DM_NAME="data"
VERITY_DM_NAME="verity-root"
ROOT_BLOCK_DEV="/dev/mapper/$VERITY_DM_NAME"

ROOT_MNT="/root"
BOOT_MNT="/boot"
BOOTUPDATE_MNT="/var/boot-update"
SECDATA_MNT="/var/secdata"
DATA_MNT="/var/data"

# Replaced by the actual value in the do_install
ROOTFS_TYPE="__ROOTFS_TYPE___"

OPT_ROOT="ro,noatime"
OPT_PART="noexec,nodev,nosuid,nosymfollow,iversion"

KMK_BLOB="$SECDATA_MNT/keys/kmk.blob"
ENC_KEY_BLOB="$SECDATA_MNT/keys/enc-key.blob"
# AES-256-XTS uses two 256-bit keys
KEY_SZ=64

HW_SERIAL="/sys/devices/soc0/serial_number"

MACHINE_ID=""

WATCHDOG_DEV="/dev/watchdog0"
WATCHDOG_PID=""

# Partition numbers for A/B slots and data
# following imx-boot-secure-bootpart.wks.in
BOOT_SLOT_A=1
ROOT_SLOT_A=2
BOOT_SLOT_B=3
ROOT_SLOT_B=4
SECDATA_PART=5
DATA_PART=6

TIMEOUT=10
BOOTLIMIT=3

AVB_PUBKEY="/etc/avb/avb_pubkey.bin"

# Init
INIT="/sbin/init"

# Source library files
LIBDIR="/usr/libexec/imx-secure"
. "$LIBDIR/init-common.sh"
. "$LIBDIR/init-ab-slot.sh"
. "$LIBDIR/init-crypto.sh"
. "$LIBDIR/init-integrity.sh"

mount_early_fs
silent_kernel_console
klog "Starting Initramfs..."
setup_slot_devices

klog "Root device: $ROOT_DEV"

# Required to make pipe work in shell
ln -s /proc/self/fd /dev/fd

# Store sealed key blobs in secdata, mounted here before the root filesystem
fsck_quiet fsck.ext4 -y "$SECDATA_DEV" || klog "fsck.ext4 on $SECDATA_DEV returned $?"
mkdir -p "$SECDATA_MNT"
mount -t ext4 -o $OPT_PART $SECDATA_DEV "$SECDATA_MNT" \
	|| fatal "cannot mount secdata device $SECDATA_DEV"
mkdir -p "$SECDATA_MNT/keys" || fatal "cannot create key directory"

setup_encrypted_rootfs

mkdir -p "$ROOT_MNT"
# Mount encrypted root filesystem
klog "Mounting encrypted root filesystem ${ROOTFS_TYPE} on $ROOT_BLOCK_DEV..."
mount -t "${ROOTFS_TYPE}" -o "$OPT_ROOT" "$ROOT_BLOCK_DEV" "$ROOT_MNT" \
	|| fatal "cannot mount root partition"

# Move the existing mount using mount(2), without updating userspace mount tables
LIBMOUNT_FORCE_MOUNT2=always mount -n --move "$SECDATA_MNT" "$ROOT_MNT$SECDATA_MNT" \
	|| fatal "cannot move secdata mount to $ROOT_MNT$SECDATA_MNT"

# Mount data partition
mount_dmcrypt_data "$DATA_DEV" "$DATA_DM_NAME" "data" "$ROOT_MNT$DATA_MNT" "$OPT_PART"
watchdog_feed_stop

fsck_quiet fsck.vfat -y -w "$BOOT_DEV" || klog "fsck on $BOOT_DEV returned $?"
mount -t vfat -o $OPT_PART $BOOT_DEV "$ROOT_MNT$BOOT_MNT" \
	|| fatal "cannot mount boot device $BOOT_DEV"

fsck_quiet fsck.vfat -y -w "$BOOTUPDATE_DEV" || klog "fsck on $BOOTUPDATE_DEV returned $?"
mount -t vfat -o $OPT_PART $BOOTUPDATE_DEV "$ROOT_MNT$BOOTUPDATE_MNT" \
	|| fatal "cannot mount boot update device $BOOTUPDATE_DEV"

# Derive the machine ID from the SoC serial number
serial=$(tr -d '\0\n' < "$HW_SERIAL") \
	|| fatal "cannot read SoC serial number"
[ -n "$serial" ] || fatal "SoC serial number is empty"
MACHINE_ID="$(printf '%s' "$serial" | sha256sum | cut -c1-32)"

# Setup EVM
setup_evm_integrity

# Switch to real root
klog "Switch to real root..."
restore_kernel_console
exec switch_root $ROOT_MNT $INIT --machine-id="$MACHINE_ID" \
	|| fatal "cannot switch_root to real root"
