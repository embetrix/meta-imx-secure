FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# OpenSSL is required for resolved's DNSSEC validation
PACKAGECONFIG:append = " openssl"

# Route DNS lookups through resolved's local stub
RESOLV_CONF = "stub-resolv"

do_install:append() {

    if [ "${IMX_SECURITY_PROFILE}" = "prod" ]; then
        # Harden systemd defaults to disable coredumps
        sed -i '/#DumpCore=/c\\DumpCore=no'                ${D}${sysconfdir}/systemd/system.conf
        sed -i '/#DefaultLimitCORE=/c\\DefaultLimitCORE=0' ${D}${sysconfdir}/systemd/system.conf
    fi

}
