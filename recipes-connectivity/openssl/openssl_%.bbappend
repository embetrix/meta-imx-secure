# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

OPENSSL_PKCS11_MODULE = "${@bb.utils.contains('OPENSSL_PKCS11_DEFAULT_PROVIDER', 'optee', 'libckteec.so.0', 'libsmw_pkcs11.so.5', d)}"
OPENSSL_PKCS11_PACKAGE = "${@bb.utils.contains('OPENSSL_PKCS11_DEFAULT_PROVIDER', 'optee', 'optee-client', 'smw', d)}"

SRC_URI:append:class-target = " file://pkcs11.cnf"

RRECOMMENDS:openssl-conf:append:class-target = " pkcs11-provider ${OPENSSL_PKCS11_PACKAGE}"

do_install:append:class-target() {
    install -d ${D}${sysconfdir}/ssl/openssl.cnf.d
    sed -e 's|@libdir@|${libdir}|g' \
        -e 's|@pkcs11_module@|${OPENSSL_PKCS11_MODULE}|g' \
        ${UNPACKDIR}/pkcs11.cnf \
        > ${D}${sysconfdir}/ssl/openssl.cnf.d/pkcs11.cnf
    chmod 0644 ${D}${sysconfdir}/ssl/openssl.cnf.d/pkcs11.cnf
}

FILES:openssl-conf:append:class-target = " ${sysconfdir}/ssl/openssl.cnf.d/pkcs11.cnf"
CONFFILES:openssl-conf:append:class-target = " ${sysconfdir}/ssl/openssl.cnf.d/pkcs11.cnf"
