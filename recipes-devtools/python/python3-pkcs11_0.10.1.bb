# SPDX-License-Identifier: MIT
SUMMARY = "PKCS#11 support for Python"
HOMEPAGE = "https://github.com/pyauth/python-pkcs11"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=f68bda54505b4002e6ec86e08125ef79"

SRC_URI[sha256sum] = "e0d7ccede3b3145a678d7c8c59b3c64dcebeb77c9146ad3394a4b1309c4ab2a2"

PYPI_PACKAGE = "python_pkcs11"

inherit pypi python_setuptools_build_meta cython

DEPENDS += "python3-setuptools-scm-native"

RDEPENDS:${PN} += " \
    python3-asn1crypto (>= 1.5.1) \
    python3-datetime \
    python3-threading \
"

BBCLASSEXTEND = "native"
