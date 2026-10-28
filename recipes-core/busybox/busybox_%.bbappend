FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'file://security-harden.cfg', '', d)} \
            "

# Disable syslog applet as it is not used and causes build issues
SRC_URI:remove = "file://syslog.cfg"
