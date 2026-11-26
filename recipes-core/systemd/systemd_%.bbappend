# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG:append = " journal-upload"

RRECOMMENDS:${PN} += "${PN}-journal-upload ${PN}-container"

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
