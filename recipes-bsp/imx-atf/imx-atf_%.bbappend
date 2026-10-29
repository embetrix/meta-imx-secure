# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Disable the UART console and debug output in production builds
SRC_URI:append = " ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'file://0001-imx-disable-uart-console.patch', '', d)}"
PACKAGECONFIG:remove = "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'debug', '', d)}"
EXTRA_OEMAKE:append = " ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', \
    'LOG_LEVEL=0 CRASH_REPORTING=0 ENABLE_BACKTRACE=0 ENABLE_CONSOLE_GETC=0', '', d)}"
