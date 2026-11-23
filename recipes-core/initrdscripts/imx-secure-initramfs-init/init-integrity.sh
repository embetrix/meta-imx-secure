#!/usr/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>
#
# Integrity helpers: EVM and AVB dm-verity setup

setup_evm_integrity() {

	# Enable EVM in signature verification mode only
	# and lock the configuration to prevent changes at runtime
	echo "0x80000002" > /sys/kernel/security/integrity/evm/evm \
	    || fatal "Failed to enable EVM signature verification"
}

# Verify AVB metadata and save the dm-verity table in dm_table
# Usage: verify_avb <device>
verify_avb() {

	if [ ! -f "$AVB_PUBKEY" ]; then
		fatal "AVB public key not found at $AVB_PUBKEY"
	fi

	klog "Verifying AVB signature on $1..."
	dm_table=$(avb_verify --dm-table -d "$1" -k "$AVB_PUBKEY") \
		|| fatal "AVB verification failed on $1"
}

# Verify AVB metadata and set up dm-verity on the decrypted root device
# Usage: setup_avb_verity <dmcrypt_name> <dmverity_name>
setup_avb_verity() {

	dev="/dev/mapper/$1"
	verity_name="$2"
	verify_avb "$dev"

	# Keep existing options and count restart_on_corruption in field 14
	# The 13 fixed fields include the start sector, length and target type
	if ! dm_table=$(printf '%s\n' "$dm_table" | awk '
		{
			if (NF == 13) {
				# Add the count field when no options are present
				print $0 " 1 restart_on_corruption"
				next
			}
			if (NF >= 14 && $14 ~ /^[0-9]+$/ && $14 == NF - 14) {
				$14 = $14 + 1
				print $0 " restart_on_corruption"
				next
			}
			printf "invalid dm-verity table (%d fields, count=%s, expected %d options)\n",
			       NF, $14, NF - 14
			exit 1
		}'); then
		fatal "cannot rewrite dm-verity table: ${dm_table:-no details}"
	fi

	klog "Setting up dm-verity as $verity_name..."
	echo "$dm_table" | dmsetup create --readonly "$verity_name" \
		|| fatal "cannot create dm-verity device $verity_name"

	# No udev in initramfs so create the device node manually
	dmsetup mknodes "$verity_name"

	klog "dm-verity $verity_name active on $dev"
}
