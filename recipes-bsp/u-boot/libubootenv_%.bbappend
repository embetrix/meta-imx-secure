# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/libubootenv:"

SRC_URI:append = " file://fw_env.config"

do_install:append:class-target() {
    install -Dm0644 ${UNPACKDIR}/fw_env.config ${D}${sysconfdir}/fw_env.config
}

FILES:${PN}-bin:append = " ${sysconfdir}/fw_env.config"
