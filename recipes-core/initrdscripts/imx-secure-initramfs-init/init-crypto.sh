#!/usr/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# Crypto helpers: plain dm-crypt with kernel keyring, rootfs encryption, data partition setup

set_rootfs_crypt_state() {

	fw_setenv rootfs_crypt "$1" \
		|| fatal "cannot save rootfs encryption state: $1"
	ROOTFS_CRYPT_STATE="$1"
}

# Read and validate the next encryption step
get_rootfs_crypt_state() {

	ROOTFS_CRYPT_STATE=$(fw_printenv -n rootfs_crypt) \
		|| fatal "cannot read rootfs encryption state"
	case "$ROOTFS_CRYPT_STATE" in
		"")
			# Existing keys need verification, never automatic replacement
			if [ ! -e "$KMK_BLOB" ] && [ ! -e "$ENC_KEY_BLOB" ]; then
				ROOTFS_CRYPT_STATE=prepare
			fi
			;;
		prepare|copy|cleanup|done) ;;
		*) fatal "unknown rootfs encryption state: $ROOTFS_CRYPT_STATE" ;;
	esac

	case "$ROOTFS_CRYPT_STATE" in
		prepare|copy|cleanup)
			# WIC puts the plaintext source in slot B
			[ "$ROOT_DEV" = "/dev/${BASE_DEV}${SEP}${ROOT_SLOT_A}" ] \
				|| fatal "rootfs encryption must finish in slot A"
			;;
	esac
}

# Usage: setup_encrypted_keys <new|load>
setup_encrypted_keys() {

	klog "Using OP-TEE trusted master key"

	if [ "$1" = new ]; then
		# No encrypted data exists yet, so interrupted key creation can restart
		rm -f "$KMK_BLOB" "$ENC_KEY_BLOB" || fatal "cannot remove unfinished keys"
		kmk_id=$(keyctl add trusted kmk "new ${KEY_SZ}" @u) \
			|| fatal "cannot create OP-TEE KMK"
		keyctl pipe "$kmk_id" > "$KMK_BLOB" \
			|| fatal "cannot export KMK to $KMK_BLOB"
		enc_key_id=$(keyctl add encrypted enc-key "new trusted:kmk ${KEY_SZ}" @u) \
			|| fatal "cannot create enc-key"
		keyctl pipe "$enc_key_id" > "$ENC_KEY_BLOB" \
			|| fatal "cannot export enc-key to ${ENC_KEY_BLOB}"
		sync
	else
		[ -s "$KMK_BLOB" ] && [ -s "$ENC_KEY_BLOB" ] \
			|| fatal "key blobs missing or empty"
		keyctl add trusted kmk "load $(cat "$KMK_BLOB")" @u >/dev/null \
			|| fatal "cannot import OP-TEE KMK from $KMK_BLOB"
		keyctl add encrypted enc-key "load $(cat "$ENC_KEY_BLOB")" @u >/dev/null \
			|| fatal "cannot import enc-key from ${ENC_KEY_BLOB}"
	fi
}

# Open a block device with plain dm-crypt using the encrypted key
# already loaded in the kernel keyring by setup_encrypted_keys().
# Usage: setup_dmcrypt <device> <dm_name>
setup_dmcrypt() {

	dev="$1"
	dm_name="$2"

	num_sectors=$(blockdev --getsz "$dev") \
		|| fatal "cannot get size of $dev"

	dmsetup create "$dm_name" --table \
		"0 $num_sectors crypt aes-xts-plain64 :${KEY_SZ}:encrypted:enc-key 0 $dev 0" \
		|| fatal "cannot open plain dm-crypt $dev as $dm_name"

	# No udev in initramfs so create the device node manually
	dmsetup mknodes "$dm_name"
}

# Copy and flush the entire image through dm-crypt
# Usage: encrypt_rootfs <source_device> <dm_name>
encrypt_rootfs() {

	enc_start=$(date +%s)
	klog "Copying $1 to encrypted root volume..."
	dd if="$1" of="/dev/mapper/$2" bs=1M conv=fsync \
		|| fatal "rootfs encryption copy failed"
	enc_end=$(date +%s)
	klog "Rootfs copy completed in $((enc_end - enc_start))s"
}

# Resume rootfs encryption, verify it and finish source cleanup
setup_encrypted_rootfs() {

	get_rootfs_crypt_state

	case "$ROOTFS_CRYPT_STATE" in
		prepare|copy|cleanup) watchdog_feed_start ;;
	esac

	# Prepare new keys or load the saved pair
	case "$ROOTFS_CRYPT_STATE" in
		prepare)
			verify_avb "$UPDATE_DEV"
			set_rootfs_crypt_state prepare
			setup_encrypted_keys new
			# Keys are flushed and must stay unchanged once copying can start
			set_rootfs_crypt_state copy
			;;
		copy)
			verify_avb "$UPDATE_DEV"
			setup_encrypted_keys load
			;;
		cleanup|done|"")
			setup_encrypted_keys load
			;;
	esac
	keyctl link @us @s || fatal "cannot link storage keys to the session keyring"
	setup_dmcrypt "$ROOT_DEV" "$ROOT_DM_NAME"

	# Keep the source intact until the encrypted root passes verification
	case "$ROOTFS_CRYPT_STATE" in
		copy)
			encrypt_rootfs "$UPDATE_DEV" "$ROOT_DM_NAME"
			setup_avb_verity "$ROOT_DM_NAME" "$VERITY_DM_NAME"
			set_rootfs_crypt_state cleanup
			;;
		cleanup|done|"")
			setup_avb_verity "$ROOT_DM_NAME" "$VERITY_DM_NAME"
			;;
	esac

	case "$ROOTFS_CRYPT_STATE" in
		cleanup)
			# After this point slot B can no longer be used as a copy source
			if ! blkdiscard -sf "$UPDATE_DEV" 2>/dev/null; then
				klog "Secure discard failed on $UPDATE_DEV, overwriting with zeros"
				zero_block_device "$UPDATE_DEV"
			fi
			set_rootfs_crypt_state done
			;;
		done) ;;
		"")
			# Keep the inactive slot when adopting an existing encrypted installation
			set_rootfs_crypt_state done
			;;
	esac
	setup_dmcrypt "$UPDATE_DEV" "$UPDATE_DM_NAME"
}

# Mount a data partition with plain dm-crypt encryption.
# First boot: open + mkfs.ext4 + mount
# Normal boot: open + mount
# Usage: mount_dmcrypt_data <device> <dm_name> <label> <mountpoint> [mount_opts]
mount_dmcrypt_data() {

	dev="$1"
	dm_name="$2"
	label="$3"
	mnt="$4"
	mnt_opts="${5:-$OPT_PART}"

	[ -n "$dev" ] || return 0

	setup_dmcrypt "$dev" "$dm_name"

	if ! blkid -s TYPE "/dev/mapper/$dm_name" >/dev/null 2>&1; then
		[ -n "$WATCHDOG_PID" ] || watchdog_feed_start
		fmt_start=$(date +%s)
		klog "Creating ext4 filesystem on $dm_name..."
		mkfs.ext4 -L "$label" "/dev/mapper/$dm_name" > /dev/null 2>&1 \
			|| fatal "cannot create filesystem on $dm_name"
		fmt_end=$(date +%s)
		klog "dm-crypt+ext4 setup of $dm_name completed in $((fmt_end - fmt_start))s"
	else
		fsck_quiet fsck.ext4 -y "/dev/mapper/$dm_name" \
			|| klog "fsck.ext4 on $dm_name returned $?"
	fi

	mkdir -p "$mnt"
	mount -o $mnt_opts -t ext4 "/dev/mapper/$dm_name" "$mnt" \
		|| fatal "cannot mount /dev/mapper/$dm_name on $mnt"
}
