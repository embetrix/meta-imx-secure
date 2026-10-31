# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

OPENSSH_CA_PUBKEY ??= ""
OPENSSH_HOST_KEY_DIR = "${sysconfdir}/ssh/keys"
OPENSSH_HOST_KEY_DIR_READONLY_CONFIG = "${sysconfdir}/ssh/keys"

SRC_URI += "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'file://sshd-time-sync.conf', '', d)}"

PACKAGECONFIG:remove = "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'systemd-sshd-socket-mode', '', d)}"
PACKAGECONFIG:append = "${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', ' systemd-sshd-service-mode', '', d)}"

# Rebuild when the production CA public key changes
do_install[file-checksums] += "${@'${OPENSSH_CA_PUBKEY}:True' if d.getVar('IMX_SECURITY_PROFILE') == 'prod' and d.getVar('OPENSSH_CA_PUBKEY') else ''}"

do_install:append () {

	if [ "${IMX_SECURITY_PROFILE}" = "prod" ]; then
		for cfg in ${D}${sysconfdir}/ssh/sshd_config ${D}${sysconfdir}/ssh/sshd_config_readonly; do
			[ -e "$cfg" ] || continue
				sed -i -e 's:#AllowTcpForwarding yes:AllowTcpForwarding no:' $cfg
				sed -i -e 's:ClientAliveCountMax 4:ClientAliveCountMax 2:' $cfg
				sed -i -e 's:#LogLevel INFO:LogLevel VERBOSE:' $cfg
				sed -i -e 's:#MaxSessions.*:MaxSessions 2:' $cfg
				sed -i -e 's:#TCPKeepAlive yes:TCPKeepAlive no:' $cfg
				sed -i -e 's:#AllowAgentForwarding yes:AllowAgentForwarding no:' $cfg
				sed -i -e 's:#PasswordAuthentication yes:PasswordAuthentication no:' $cfg
				sed -i -e 's:#PermitRootLogin.*:PermitRootLogin prohibit-password:' $cfg
				echo 'TrustedUserCAKeys ${sysconfdir}/ssh/certs/ssh_ca.pub' >> "$cfg"
		done
	fi

	# Host keys are bind-mounted from /var/data/etc/ssh/keys
	install -d ${D}${sysconfdir}/ssh/keys

	install -d ${D}${sysconfdir}/ssh/certs
	if [ "${IMX_SECURITY_PROFILE}" = "prod" ]; then
		if [ -z "${OPENSSH_CA_PUBKEY}" ] || [ ! -f "${OPENSSH_CA_PUBKEY}" ]; then
			bbfatal "Production build requires OPENSSH_CA_PUBKEY to be set to a valid SSH CA public key"
		fi
		install -m 0644 "${OPENSSH_CA_PUBKEY}" ${D}${sysconfdir}/ssh/certs/ssh_ca.pub

		# Wait for time sync before checking certificate validity
		install -d ${D}${systemd_system_unitdir}/sshd.service.d
		install -m 0644 ${UNPACKDIR}/sshd-time-sync.conf ${D}${systemd_system_unitdir}/sshd.service.d/time-sync.conf
	fi
}

FILES:${PN}-sshd += " \
    ${sysconfdir}/ssh/certs \
    ${sysconfdir}/ssh/keys \
    ${systemd_system_unitdir}/sshd.service.d \
"
