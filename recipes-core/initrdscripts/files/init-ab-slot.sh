#!/usr/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# A/B slot detection from the root partition passed by U-Boot

setup_block_devices() {

	# Use the last root= argument, as the kernel does
	root_spec=$(awk '
		{ for (i = 1; i <= NF; i++) if ($i ~ /^root=/) root = substr($i, 6) }
		END { print root }
	' /proc/cmdline) || fatal "cannot read kernel command line"

	case "$root_spec" in
		/dev/*|PARTUUID=?*|PARTLABEL=?*) ;;
		*) fatal "unsupported or missing root= argument: $root_spec" ;;
	esac

	case "$root_spec" in
		/dev/*) ROOT_DEV="$root_spec" ;;
		*)
			# No udev in initramfs, so resolve partition tags with blkid
			attempt=0
			while [ "$attempt" -lt "$TIMEOUT" ]; do
				ROOT_DEV=$(blkid -c /dev/null -t "$root_spec" -o device)
				case "$ROOT_DEV" in
					*[[:space:]]*) fatal "root= matches more than one device: $root_spec" ;;
					?*) break ;;
				esac
				attempt=$((attempt + 1))
				sleep 0.1
			done
			[ -n "$ROOT_DEV" ] || fatal "timeout resolving root=$root_spec"
			;;
	esac
	await_blockdev "$ROOT_DEV"

	ROOT_DEV=$(readlink -f "$ROOT_DEV") || fatal "cannot resolve root device"
	root_name=${ROOT_DEV##*/}
	root_sysfs=$(readlink -f "/sys/class/block/$root_name") \
		|| fatal "cannot find root device in sysfs"
	root_part=$(cat "$root_sysfs/partition") \
		|| fatal "root device is not a disk partition: $ROOT_DEV"
	disk_sysfs=${root_sysfs%/*}
	BASE_DEV=${disk_sysfs##*/}

	# MMC and NVMe partition names need a separator
	case "$BASE_DEV" in
		*[0-9]) SEP="p" ;;
		*) SEP="" ;;
	esac
	[ "$ROOT_DEV" = "/dev/${BASE_DEV}${SEP}${root_part}" ] \
		|| fatal "unexpected root partition path: $ROOT_DEV"

	case "$root_part" in
		"$ROOT_SLOT_A")
			klog "Boot slot A"
			BOOT_DEV="/dev/${BASE_DEV}${SEP}${BOOT_SLOT_A}"
			BOOTUPDATE_DEV="/dev/${BASE_DEV}${SEP}${BOOT_SLOT_B}"
			UPDATE_DEV="/dev/${BASE_DEV}${SEP}${ROOT_SLOT_B}"
			;;
		"$ROOT_SLOT_B")
			klog "Boot slot B"
			BOOT_DEV="/dev/${BASE_DEV}${SEP}${BOOT_SLOT_B}"
			BOOTUPDATE_DEV="/dev/${BASE_DEV}${SEP}${BOOT_SLOT_A}"
			UPDATE_DEV="/dev/${BASE_DEV}${SEP}${ROOT_SLOT_A}"
			;;
		*) fatal "root partition is not slot A or B: $ROOT_DEV" ;;
	esac
	SECDATA_DEV="/dev/${BASE_DEV}${SEP}${SECDATA_PART}"
	DATA_DEV="/dev/${BASE_DEV}${SEP}${DATA_PART}"

	ln -sf "/dev/$BASE_DEV" /dev/bootdev \
		|| fatal "cannot create boot device link"
}
