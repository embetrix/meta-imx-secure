# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Confirm a pending update after boot health checks"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://imx-update-confirm \
    file://imx-update-confirm.conf \
    file://imx-update-confirm.service \
    file://imx-update-confirm.timer \
"

inherit allarch systemd

RDEPENDS:${PN} = "libubootenv-bin swupdate"
SYSTEMD_SERVICE:${PN} = "imx-update-confirm.timer"
FILES:${PN} += "${systemd_system_unitdir}/imx-update-confirm.service"
CONFFILES:${PN} = "${sysconfdir}/default/imx-update-confirm"

do_install() {
    install -Dm0755 ${UNPACKDIR}/imx-update-confirm ${D}${sbindir}/imx-update-confirm
    install -Dm0644 ${UNPACKDIR}/imx-update-confirm.conf ${D}${sysconfdir}/default/imx-update-confirm
    install -Dm0644 ${UNPACKDIR}/imx-update-confirm.service ${D}${systemd_system_unitdir}/imx-update-confirm.service
    install -Dm0644 ${UNPACKDIR}/imx-update-confirm.timer ${D}${systemd_system_unitdir}/imx-update-confirm.timer
    sed -i -e 's|@SBINDIR@|${sbindir}|g' -e 's|@SYSCONFDIR@|${sysconfdir}|g' \
        ${D}${systemd_system_unitdir}/imx-update-confirm.service
}
