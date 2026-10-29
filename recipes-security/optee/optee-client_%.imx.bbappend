# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Enable client and supplicant debug traces in development, disable logs in production
EXTRA_OECMAKE:append = " \
    -DCFG_TEE_CLIENT_LOG_LEVEL=${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', '3', '0', d)} \
    -DCFG_TEE_SUPP_LOG_LEVEL=${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', '3', '0', d)} \
"

SRC_URI += "file://tee-supplicant-storage.conf"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}/tee-supplicant@.service.d
    sed -e 's|@base_bindir@|${base_bindir}|g' \
        -e 's|@sbindir@|${sbindir}|g' \
        -e 's|@localstatedir@|${localstatedir}|g' \
        ${UNPACKDIR}/tee-supplicant-storage.conf \
        > ${D}${systemd_system_unitdir}/tee-supplicant@.service.d/storage.conf
    chmod 0644 ${D}${systemd_system_unitdir}/tee-supplicant@.service.d/storage.conf
}

FILES:${PN} += "${systemd_system_unitdir}/tee-supplicant@.service.d"
