# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Software version for the SPL/U-Boot, ATF and OP-TEE container
SW_VERSION ?= "1"
MKIMAGE_EXTRA_ARGS:append = " ROLLBACK_INDEX_IN_CONTAINER=${SW_VERSION}"

inherit_defer ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', 'imx-boot-sign', '', d)}
