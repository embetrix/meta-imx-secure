# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# OpenSSL is required for resolved's DNSSEC validation
PACKAGECONFIG:append = " journal-upload openssl"

RRECOMMENDS:${PN} += "${PN}-journal-upload ${PN}-container"

# Route DNS lookups through resolved's local stub
RESOLV_CONF = "stub-resolv"

WATCHDOG_RUNTIME_SEC = "15s"
# The i.MX7ULP watchdog driver allows at most 128 seconds
WATCHDOG_TIMEOUT = "60s"

# Enable uploads when a log server is configured
SYSTEMD_AUTO_ENABLE:${PN}-journal-upload = "disable"

do_install:append() {

    if [ "${IMX_SECURITY_PROFILE}" = "prod" ]; then
        # Disable serial login
        install -d ${D}${sysconfdir}/systemd/system
        ln -sf /dev/null ${D}${sysconfdir}/systemd/system/serial-getty@.service
    fi
}
