#!/usr/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# U-Boot sets root= and boot_slot= on the kernel command line
# Use root= to find the disk and boot_slot= to select its A/B partitions

setup_slot_devices() {

	# Use the last root= argument, as the kernel does
	root_spec=$(awk '
		{ for (i = 1; i <= NF; i++) if ($i ~ /^root=/) root = substr($i, 6) }
		END { print root }
	' /proc/cmdline) || fatal "cannot read kernel command line"

	# Keep the prefix to distinguish a missing argument from boot_slot=
	boot_slot_arg=$(awk '
		{ for (i = 1; i <= NF; i++) if ($i ~ /^boot_slot=/) slot = $i }
		END { print slot }
	' /proc/cmdline) || fatal "cannot read boot slot"
	case "$boot_slot_arg" in
		""|boot_slot=a|boot_slot=b) ;;
		*) fatal "invalid boot slot: $boot_slot_arg" ;;
	esac

	case "$root_spec" in
		/dev/*|PARTUUID=?*|PARTLABEL=?*) ;;
		*) fatal "unsupported or missing root= argument: $root_spec" ;;
	esac

	await_blockdev "$root_spec"
	ROOT_DEV="$BLOCK_DEV"

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

	# root= must identify a root slot on the disk, even when selecting the other slot
	case "$root_part" in
		"$ROOT_SLOT_A"|"$ROOT_SLOT_B") ;;
		*) fatal "root partition is not slot A or B: $ROOT_DEV" ;;
	esac

	# Older bootloaders without boot_slot= keep the slot selected by root=
	case "$boot_slot_arg" in
		boot_slot=a) root_part="$ROOT_SLOT_A" ;;
		boot_slot=b) root_part="$ROOT_SLOT_B" ;;
	esac
	ROOT_DEV="/dev/${BASE_DEV}${SEP}${root_part}"
	await_blockdev "$ROOT_DEV"

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
	esac
	SECDATA_DEV="/dev/${BASE_DEV}${SEP}${SECDATA_PART}"
	DATA_DEV="/dev/${BASE_DEV}${SEP}${DATA_PART}"

	ln -sf "/dev/$BASE_DEV" /dev/bootdev \
		|| fatal "cannot create boot device link"
}
