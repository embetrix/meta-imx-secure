FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://wpa_supplicant@.service \
            file://wpa_supplicant-mlan0.conf \
            file://80-mlan-interface.rules"

SYSTEMD_AUTO_ENABLE = "disable"

do_install:append () {

   install -m 644 ${UNPACKDIR}/wpa_supplicant@.service ${D}/${systemd_system_unitdir}
   install -d ${D}${sysconfdir}/wpa_supplicant/
   install -D -m 600 ${UNPACKDIR}/wpa_supplicant-mlan0.conf ${D}${sysconfdir}/wpa_supplicant/

   install -d ${D}${sysconfdir}/udev/rules.d
   install -m 0644 ${UNPACKDIR}/80-mlan-interface.rules ${D}${sysconfdir}/udev/rules.d
}

FILES:${PN} += "${sysconfdir}/udev/rules.d"
