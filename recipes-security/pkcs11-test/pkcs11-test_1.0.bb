# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "PKCS#11 tests for OP-TEE and SMW"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://pkcs11-test"
S = "${UNPACKDIR}"

RDEPENDS:${PN} = "bash opensc openssl-bin coreutils diffutils"

do_install() {
    install -d ${D}${bindir}
    sed 's|@libdir@|${libdir}|g' ${UNPACKDIR}/pkcs11-test > ${D}${bindir}/pkcs11-test
    chmod 0755 ${D}${bindir}/pkcs11-test
}
