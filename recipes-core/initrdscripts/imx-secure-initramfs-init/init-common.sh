#!/usr/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# Common helpers: logging, early mounts, block device wait

fatal() {

	echo "FATAL: $1" >&2
	reboot -f
	exit 1
	#sh
}

klog() {

	printf '%s\n' "$*"
	printf '<6>Initramfs: %s\n' "$*" > /dev/kmsg
}

# Show fsck output only when it returns a nonzero status
fsck_quiet() (

	fsck_output=$("$@" 2>&1)
	fsck_status=$?
	if [ "$fsck_status" -ne 0 ]; then
		printf '%s\n' "$fsck_output" >&2
	fi
	exit "$fsck_status"
)

silent_kernel_console() {

	KERNEL_PRINTK=$(cat /proc/sys/kernel/printk) || return 1
	# Keep only emergency kernel messages on the console
	echo 1 > /proc/sys/kernel/printk
}

restore_kernel_console() {

	[ -n "${KERNEL_PRINTK:-}" ] || return 0
	printf '%s\n' "$KERNEL_PRINTK" > /proc/sys/kernel/printk
}

mount_early_fs() {

	mount -t devtmpfs none /dev
	mount -t tmpfs tmp /tmp
	mount -t proc proc /proc
	mount -t sysfs sysfs /sys
	mount -t securityfs securityfs /sys/kernel/security
}

# Wait for a device path or partition tag and set BLOCK_DEV
await_blockdev() {

	i=0
	while [ "$i" -lt "$TIMEOUT" ]; do
		case "$1" in
			PARTUUID=*|PARTLABEL=*)
				# No udev in initramfs, so resolve partition tags with blkid
				BLOCK_DEV=$(blkid -c /dev/null -t "$1" -o device)
				case "$BLOCK_DEV" in
					*[[:space:]]*) fatal "multiple block devices match $1" ;;
				esac
				;;
			*) BLOCK_DEV="$1" ;;
		esac
		test -b "$BLOCK_DEV" && return 0
		i=$((i + 1))
		sleep 0.1
	done
	fatal "Timeout waiting for $1"
}

watchdog_feed_start() {

	[ -e "$WATCHDOG_DEV" ] || return 0
	klog "Feeding watchdog $WATCHDOG_DEV"
	watchdog -F -T 15 -t 5 "$WATCHDOG_DEV" &
	WATCHDOG_PID=$!
}

watchdog_feed_stop() {

	[ -n "$WATCHDOG_PID" ] || return 0
	klog "Stopping watchdog feed"
	kill "$WATCHDOG_PID" 2>/dev/null
	WATCHDOG_PID=""
}
