# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Keep xtest without the filesystem TAs
do_install:append() {
    rm -f ${D}${nonarch_base_libdir}/optee_armtz/*.ta
}
