# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

DEPENDS:append = " smw ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', 'optee-pqc', '', d)}"

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
# Production security limitation: stored data has no rollback protection
# An attacker can restore an older valid snapshot including fTPM and PKCS#11 state
# RPMB rollback protection requires a provisioned authentication key
# Provisioning that key is irreversible and it cannot be changed afterwards
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

# Embed out of tree SMW's TEE backend and the development PQC TA
EXTRA_OEMAKE:append = " \
    EARLY_TA_PATHS+=${STAGING_DATADIR}/optee-smw/11b5c4aa-6d20-11ea-bc55-0242ac130003.stripped.elf \
    ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', \
               'EARLY_TA_PATHS+=${STAGING_DATADIR}/optee-pqc/7b1e6f40-9c32-4da8-a567-71930c4e82b6.stripped.elf', '', d)} \
"

# Keep only the embedded early TAs
do_install:append() {
    rm -rf ${D}${nonarch_base_libdir}/optee_armtz
}
