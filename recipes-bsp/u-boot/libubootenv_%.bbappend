# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/libubootenv:"

SRC_URI:append = " file://fw_env.config"

do_install:append:class-target() {
    install -Dm0644 ${UNPACKDIR}/fw_env.config ${D}${sysconfdir}/fw_env.config
}

PACKAGES:prepend:class-target = "${PN}-config "
FILES:${PN}-config:class-target = "${sysconfdir}/fw_env.config"
RDEPENDS:${PN}-config:append:class-target = " u-boot-imx-env"
RDEPENDS:${PN}-bin:append:class-target = " ${PN}-config"
