# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://0001-mkimage-default-ahab-software-version.patch"

# Software version for generated AHAB containers, including the ROM boot container
SW_VERSION ?= "1"
export IMX_MKIMAGE_SW_VERSION = "${SW_VERSION}"
MKIMAGE_EXTRA_ARGS:append = " ROLLBACK_INDEX_IN_CONTAINER=${SW_VERSION}"

inherit_defer ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', 'imx-boot-sign', '', d)}
