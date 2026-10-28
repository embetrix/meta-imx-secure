FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://var-data.mount"
SYSTEMD_SERVICE:${PN} += "var-data.mount"

# Explicitly disable OverlayFS and default to bind mounts
AVOID_OVERLAYFS = "1"

# Persistent binds on the data partition
VOLATILE_BINDS:append = "\
${localstatedir}/data${sysconfdir}/ssh/keys         ${sysconfdir}/ssh/keys\n\
${localstatedir}/data${sysconfdir}/systemd/network/ ${sysconfdir}/systemd/network/\n\
${@bb.utils.contains('MACHINE_FEATURES', 'wifi', '${localstatedir}/data${sysconfdir}/wpa_supplicant ${sysconfdir}/wpa_supplicant\\n', '', d)}\
${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', '${localstatedir}/data${ROOT_HOME} ${ROOT_HOME}\\n', '', d)}"
