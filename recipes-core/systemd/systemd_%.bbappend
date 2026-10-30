# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# OpenSSL is required for resolved's DNSSEC validation
PACKAGECONFIG:append = " journal-upload openssl"

RRECOMMENDS:${PN} += "${PN}-journal-upload ${PN}-container"

# Route DNS lookups through resolved's local stub
RESOLV_CONF = "stub-resolv"

WATCHDOG_RUNTIME_SEC = "15s"
WATCHDOG_TIMEOUT = "10min"

# Enable uploads when a log server is configured
SYSTEMD_AUTO_ENABLE:${PN}-journal-upload = "disable"

do_install:append() {

    if [ "${IMX_SECURITY_PROFILE}" = "prod" ]; then
        # Disable serial login
        install -d ${D}${sysconfdir}/systemd/system
        ln -sf /dev/null ${D}${sysconfdir}/systemd/system/serial-getty@.service

        # Harden systemd defaults to disable coredumps
        sed -i '/#DumpCore=/c\\DumpCore=no'                ${D}${sysconfdir}/systemd/system.conf
        sed -i '/#DefaultLimitCORE=/c\\DefaultLimitCORE=0' ${D}${sysconfdir}/systemd/system.conf
    fi

    # Limit journald size
    sed -i '/#SystemMaxUse=/c\\SystemMaxUse=256M'          ${D}${sysconfdir}/systemd/journald.conf
    sed -i '/#SystemMaxFileSize=/c\\SystemMaxFileSize=32M' ${D}${sysconfdir}/systemd/journald.conf
    sed -i '/#RuntimeMaxUse=/c\\RuntimeMaxUse=64M'         ${D}${sysconfdir}/systemd/journald.conf
}
