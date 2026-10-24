# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Load user TAs only from the embedded early TA store
# TA loading from REE filesystems is disabled
EXTRA_OEMAKE:append = " \
    CFG_EARLY_TA=y \
    CFG_REE_FS_TA=n \
    CFG_SECSTOR_TA=n \
    CFG_PKCS11_TA=y \
    CFG_IN_TREE_EARLY_TAS+=pkcs11/fd02c9da-306c-48c7-a49c-bbd827ae86ee \
    CFG_IN_TREE_EARLY_TAS+=trusted_keys/f04a0fe7-1f5d-4b9b-abf7-619b85b4ce8c \
    CFG_IN_TREE_EARLY_TAS+=avb/023f8f1a-292a-432b-8fc4-de8471358067 \
"

# Keep only the embedded early TAs
do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/optee_armtz/*.ta
}
