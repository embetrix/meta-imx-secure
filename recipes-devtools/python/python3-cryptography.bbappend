# SPDX-License-Identifier: MIT
# SPSDK 3.12 requires cryptography >= 48.0.1 and < 50
PV = "49.0.0"
SRC_URI[sha256sum] = "f89660a348f4f78a92366240a61404e337586ef7f5909a2fef59ca88ef505493"

# The old backports are already in this release
SRC_URI = "file://0001-pyproject.toml-remove-benchmark-disable-option.patch \
           file://check-memfree.py \
           file://run-ptest"

require python3-cryptography-49-crates.inc

# Use Yocto's Python headers instead of guessing from PYO3_CROSS_LIB_DIR
CFLAGS:append = " -I${STAGING_INCDIR}/${PYTHON_DIR}"
