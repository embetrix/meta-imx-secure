FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://timesyncd.conf \
    file://journal-upload.conf \
    file://80-wlan.network \
    file://rfkill-override.conf \
    file://resolved.conf \
    ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'file://security-harden.conf', '', d)} \
"

do_install:append() {
	if [ "${IMX_SECURITY_PROFILE}" = "prod" ]; then
		install -d ${D}${sysconfdir}/sysctl.d
		install -m 644 ${UNPACKDIR}/security-harden.conf ${D}${sysconfdir}/sysctl.d/90-security-harden.conf
	fi

	for config in resolved timesyncd journal-upload; do
		install -D -m 0644 "${UNPACKDIR}/$config.conf" \
			"${D}${systemd_unitdir}/$config.conf.d/60-imx-secure.conf"
	done

	install -d ${D}/${systemd_unitdir}/network
	install -m 644 ${UNPACKDIR}/80-wlan.network ${D}/${systemd_unitdir}/network/

	# Drop-in: defer systemd-rfkill until /var/lib volatile-bind is in place
	install -d ${D}${systemd_system_unitdir}/systemd-rfkill.service.d
	install -m 644 ${UNPACKDIR}/rfkill-override.conf \
		${D}${systemd_system_unitdir}/systemd-rfkill.service.d/override.conf
}

FILES:${PN} += " \
    ${sysconfdir}/sysctl.d \
    ${systemd_unitdir}/resolved.conf.d \
    ${systemd_unitdir}/timesyncd.conf.d \
    ${systemd_unitdir}/journal-upload.conf.d \
    ${systemd_system_unitdir}/systemd-rfkill.service.d \
"
