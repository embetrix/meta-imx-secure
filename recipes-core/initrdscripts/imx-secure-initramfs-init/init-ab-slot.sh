#!/usr/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# U-Boot sets root= and boot_slot= on the kernel command line
# Use root= to find the disk and boot_slot= to select its A/B partitions

# AHAB header patterns: version, two length bytes, tag
AHAB_V1_HEADER_PATTERN='00????87'
AHAB_V1_FOR_V2_HEADER_PATTERN='00????82'
AHAB_V2_HEADER_PATTERN='02????87'

rollback() {

	case "$boot_slot_arg" in
		boot_slot=a)
			failed_offset=$IMX_BOOT_A_OFFSET
			fallback_offset=$IMX_BOOT_B_OFFSET
			fallback_slot=b
			;;
		boot_slot=b)
			failed_offset=$IMX_BOOT_B_OFFSET
			fallback_offset=$IMX_BOOT_A_OFFSET
			fallback_slot=a
			;;
		*) fatal "rollback needs a boot_slot from the bootloader" ;;
	esac

	# Keep rollback_slot and ustate for userspace to report the failed update
	if [ "$rollback_slot" = "${boot_slot_arg#boot_slot=}" ]; then
		fw_setenv -s - <<EOF || fatal "cannot finish rollback"
boot_slot=$rollback_slot
upgrade_available=0
bootcount=0
ustate=3
EOF
		klog "Rollback completed on slot $rollback_slot"
		return 0
	fi

	fw_boot_slot=$(fw_printenv -n boot_slot) \
		|| fatal "cannot read boot slot for rollback"
	[ "$fw_boot_slot" = "${boot_slot_arg#boot_slot=}" ] \
		|| fatal "cannot invalidate firmware with a boot slot mismatch"
	[ "$IMX_BOOT_A_OFFSET" -gt 0 ] \
		&& [ "$IMX_BOOT_MAX_SIZE" -gt 0 ] \
		&& [ $((IMX_BOOT_A_OFFSET % 512)) -eq 0 ] \
		&& [ $((IMX_BOOT_B_OFFSET % 512)) -eq 0 ] \
		&& [ $((IMX_BOOT_MAX_SIZE % 512)) -eq 0 ] \
		&& [ $((IMX_BOOT_A_OFFSET + IMX_BOOT_MAX_SIZE)) -le "$IMX_BOOT_B_OFFSET" ] \
		|| fatal "invalid boot firmware offsets or size"

	# This only checks the header, the ROM still authenticates the fallback
	header=$(hexdump -v -s "$fallback_offset" -n 4 -e '4/1 "%02x"' /dev/bootdev) \
		|| fatal "cannot read fallback firmware header"
	case "$header" in
		$AHAB_V1_HEADER_PATTERN|$AHAB_V1_FOR_V2_HEADER_PATTERN|$AHAB_V2_HEADER_PATTERN) ;;
		*)
			[ -z "$rollback_slot" ] || fatal "rollback target has no AHAB header"
			klog "Rollback unavailable: slot $fallback_slot has no AHAB header"
			return 0
			;;
	esac

	# Keep the target across power cuts until it boots
	fw_setenv -s - <<EOF || fatal "cannot record rollback target"
rollback_slot=$fallback_slot
ustate=3
EOF
	klog "Invalidating firmware slot ${boot_slot_arg#boot_slot=} for rollback to $fallback_slot"
	dd if=/dev/zero of=/dev/bootdev bs=512 conv=fsync \
		seek=$((failed_offset / 512)) count=$((IMX_BOOT_MAX_SIZE / 512)) \
		|| fatal "cannot invalidate failed firmware"
	reboot -f
	exit 1
}

check_boot_attempts() {

	upgrade_available=$(fw_printenv -n upgrade_available) \
		|| fatal "cannot read pending update state"
	[ "$upgrade_available" = "1" ] || return 0

	rollback_slot=$(fw_printenv -n rollback_slot) \
		|| fatal "cannot read rollback target"
	case "$rollback_slot" in
		"") ;;
		a|b) rollback; return 0 ;;
		*) fatal "invalid rollback target: $rollback_slot" ;;
	esac

	bootcount=$(fw_printenv -n bootcount) \
		|| fatal "cannot read update boot count"
	bootcount=${bootcount:-0}
	case "$bootcount" in
		*[!0-9]*) fatal "invalid update boot count: $bootcount" ;;
	esac
	# Strip leading zeros before shell arithmetic
	bootcount=$(printf '%s' "$bootcount" | sed 's/^0*//')
	bootcount=${bootcount:-0}
	if [ "$bootcount" -lt "$BOOTLIMIT" ]; then
		bootcount=$((bootcount + 1))
		fw_setenv bootcount "$bootcount" \
			|| fatal "cannot save update boot count"
	fi
	klog "Pending update boot attempt: $bootcount"
	if [ "$bootcount" -ge "$BOOTLIMIT" ]; then
		klog "Update boot limit reached ($bootcount/$BOOTLIMIT)"
		rollback
	fi
}

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

	check_boot_attempts

	if [ -n "$boot_slot_arg" ]; then
		fw_boot_slot=$(fw_printenv -n boot_slot) \
			|| fatal "cannot read boot slot from firmware environment"
		case "$fw_boot_slot" in
			"") ;; # Fresh images have no stored boot slot
			a|b)
				[ "$fw_boot_slot" = "${boot_slot_arg#boot_slot=}" ] \
					|| fatal "boot slot mismatch: cmdline=${boot_slot_arg#boot_slot=} fwenv=$fw_boot_slot"
				;;
			*) fatal "invalid boot slot in firmware environment: $fw_boot_slot" ;;
		esac
	fi
}
