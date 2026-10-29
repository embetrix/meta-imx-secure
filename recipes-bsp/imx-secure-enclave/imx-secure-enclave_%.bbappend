# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://nvm-daemon-storage.conf"

SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install:append() {
    sed -i -e 's|^NVMD_STORAGE_DIRNAME=.*|NVMD_STORAGE_DIRNAME=${localstatedir}/secdata/ele/|' \
        -e 's|^NVMD_STORAGE_FILENAME=.*|NVMD_STORAGE_FILENAME=${localstatedir}/secdata/ele/ele_nvm_master|' \
        ${D}${sysconfdir}/nvmd.conf

    install -d ${D}${systemd_system_unitdir}/nvm_daemon.service.d
    sed -e 's|@base_bindir@|${base_bindir}|g' \
        -e 's|@localstatedir@|${localstatedir}|g' \
        ${UNPACKDIR}/nvm-daemon-storage.conf \
        > ${D}${systemd_system_unitdir}/nvm_daemon.service.d/storage.conf
    chmod 0644 ${D}${systemd_system_unitdir}/nvm_daemon.service.d/storage.conf
}

FILES:${PN} += "${systemd_system_unitdir}/nvm_daemon.service.d"
