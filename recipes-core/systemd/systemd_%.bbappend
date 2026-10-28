FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# OpenSSL is required for resolved's DNSSEC validation
PACKAGECONFIG:append = " openssl"

# Route DNS lookups through resolved's local stub
RESOLV_CONF = "stub-resolv"
