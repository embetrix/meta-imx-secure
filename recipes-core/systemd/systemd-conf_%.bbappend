# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://timesyncd.conf \
    file://journal-upload.conf \
    file://journald-persistent.conf \
    file://journal-flush-override.conf \
    file://80-wlan.network \
    file://rfkill-override.conf \
    ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'file://security-harden.conf file://system-hardening.conf', '', d)} \
"

# Use a full board reset for normal reboots on i.MX95
SRC_URI:append:mx95-nxp-bsp = " file://board-reset.conf"

do_install:append() {
	if [ "${IMX_SECURITY_PROFILE}" = "prod" ]; then
		install -d ${D}${sysconfdir}/sysctl.d
		install -m 644 ${UNPACKDIR}/security-harden.conf ${D}${sysconfdir}/sysctl.d/90-security-harden.conf
		install -D -m 0644 ${UNPACKDIR}/system-hardening.conf \
			${D}${systemd_unitdir}/system.conf.d/60-imx-secure.conf
	fi

	for config in timesyncd journal-upload; do
		install -D -m 0644 "${UNPACKDIR}/$config.conf" \
			"${D}${systemd_unitdir}/$config.conf.d/60-imx-secure.conf"
	done

	install -D -m 0644 ${UNPACKDIR}/journald-persistent.conf \
		${D}${systemd_unitdir}/journald.conf.d/60-imx-secure.conf
	install -D -m 0644 ${UNPACKDIR}/journal-flush-override.conf \
		${D}${systemd_system_unitdir}/systemd-journal-flush.service.d/60-imx-secure.conf

	install -d ${D}/${systemd_unitdir}/network
	install -m 644 ${UNPACKDIR}/80-wlan.network ${D}/${systemd_unitdir}/network/

	# Drop-in: defer systemd-rfkill until /var/lib volatile-bind is in place
	install -d ${D}${systemd_system_unitdir}/systemd-rfkill.service.d
	install -m 644 ${UNPACKDIR}/rfkill-override.conf \
		${D}${systemd_system_unitdir}/systemd-rfkill.service.d/override.conf
}

do_install:append:mx95-nxp-bsp() {
	install -D -m 0644 ${UNPACKDIR}/board-reset.conf \
		${D}${systemd_system_unitdir}/systemd-reboot.service.d/board-reset.conf
}

FILES:${PN} += " \
    ${sysconfdir}/sysctl.d \
    ${systemd_unitdir}/timesyncd.conf.d \
    ${systemd_unitdir}/journal-upload.conf.d \
    ${systemd_system_unitdir}/systemd-journal-flush.service.d \
    ${systemd_system_unitdir}/systemd-rfkill.service.d \
"

FILES:${PN}:append:mx95-nxp-bsp = " ${systemd_system_unitdir}/systemd-reboot.service.d"
