FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://timesyncd.conf \
    file://rfkill-override.conf \
    file://resolved.conf \
"

do_install:append() {
	for config in resolved timesyncd; do
		install -D -m 0644 "${UNPACKDIR}/$config.conf" \
			"${D}${systemd_unitdir}/$config.conf.d/60-imx-secure.conf"
	done

	# Drop-in: defer systemd-rfkill until /var/lib volatile-bind is in place
	install -d ${D}${systemd_system_unitdir}/systemd-rfkill.service.d
	install -m 644 ${UNPACKDIR}/rfkill-override.conf \
		${D}${systemd_system_unitdir}/systemd-rfkill.service.d/override.conf
}

FILES:${PN} += " \
    ${systemd_unitdir}/resolved.conf.d \
    ${systemd_unitdir}/timesyncd.conf.d \
    ${systemd_system_unitdir}/systemd-rfkill.service.d \
"
