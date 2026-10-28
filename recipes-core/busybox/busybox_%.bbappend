# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://watchdog.cfg \
            ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'file://security-harden.cfg', '', d)} \
            "
