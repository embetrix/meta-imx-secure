# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Log only core and TA errors in development builds, stay silent in production
EXTRA_OEMAKE:append = " \
    CFG_TEE_CORE_LOG_LEVEL=${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', '1', '0', d)} \
    CFG_TEE_TA_LOG_LEVEL=${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', '1', '0', d)} \
"

# Allow insecure fallbacks only in development builds
# REE storage is encrypted but has no rollback protection
EXTRA_OEMAKE:append = " CFG_INSECURE=${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', 'y', 'n', d)}"

# Disable embedded tests, stack unwinding and attestation
# Core assertions stay enabled
EXTRA_OEMAKE:append = " \
    CFG_ENABLE_EMBEDDED_TESTS=n \
    CFG_UNWIND=n \
    CFG_ATTESTATION_PTA=n \
"

# Load user TAs only from the embedded early TA store
# Disable TA loading from REE and secure storage filesystems
EXTRA_OEMAKE:append = " \
    CFG_EARLY_TA=y \
    CFG_REE_FS_TA=n \
    CFG_SECSTOR_TA=n \
"

# Store PKCS#11 data in encrypted REE storage without accessing RPMB
# AVB persistent storage remains unavailable without RPMB
EXTRA_OEMAKE:append = " \
    CFG_REE_FS=y \
    CFG_RPMB_FS=n \
    CFG_REE_FS_INTEGRITY_RPMB=n \
    CFG_RPMB_TESTKEY=n \
    CFG_RPMB_WRITE_KEY=n \
"

# Embed PKCS#11, trusted_keys and AVB TAs in OP-TEE
EXTRA_OEMAKE:append = " \
    CFG_PKCS11_TA=y \
    CFG_IN_TREE_EARLY_TAS+=pkcs11/fd02c9da-306c-48c7-a49c-bbd827ae86ee \
    CFG_IN_TREE_EARLY_TAS+=trusted_keys/f04a0fe7-1f5d-4b9b-abf7-619b85b4ce8c \
    CFG_IN_TREE_EARLY_TAS+=avb/023f8f1a-292a-432b-8fc4-de8471358067 \
"

# Keep only the embedded early TAs
do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/optee_armtz/*.ta
}
