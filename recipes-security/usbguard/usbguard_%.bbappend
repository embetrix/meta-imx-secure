# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://rules.conf \
            file://usbguard-daemon.conf \
            "

DEPENDS += "audit"
RDEPENDS:${PN} += "auditd"

EXTRA_OECONF += "--enable-audit"

do_install:append() {
    install -d ${D}${sysconfdir}/usbguard
    install -m 0600 ${UNPACKDIR}/rules.conf ${D}${sysconfdir}/usbguard/
    install -m 0600 ${UNPACKDIR}/usbguard-daemon.conf ${D}${sysconfdir}/usbguard/
}
