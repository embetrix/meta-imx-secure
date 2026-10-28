# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://firewall.nft \
    file://nftables.service \
    file://network-firewall.conf \
    "

inherit systemd

SYSTEMD_SERVICE:${PN} = "nftables.service"

do_install:append() {
    install -d ${D}${sysconfdir}/nftables
    install -m 0644 ${UNPACKDIR}/firewall.nft ${D}${sysconfdir}/nftables/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/nftables.service ${D}${systemd_system_unitdir}/

    # Keep network services stopped if the firewall cannot load
    for unit in systemd-networkd.service wpa_supplicant@.service; do
        install -d ${D}${systemd_system_unitdir}/${unit}.d
        install -m 0644 ${UNPACKDIR}/network-firewall.conf \
            ${D}${systemd_system_unitdir}/${unit}.d/nftables.conf
    done
}

FILES:${PN} += " \
    ${sysconfdir}/nftables \
    ${systemd_system_unitdir}/systemd-networkd.service.d/nftables.conf \
    ${systemd_system_unitdir}/wpa_supplicant@.service.d/nftables.conf \
"
