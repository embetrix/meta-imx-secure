# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "PKCS#11 signature provider for NXP SPSDK"
HOMEPAGE = "https://github.com/nxp-mcuxpresso/spsdk_plugins/tree/master/pkcs11"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=fe2a425fb1f291c670f58b9e3771878e"

SRC_URI[sha256sum] = "fc7b61eed173a549fe84bb8c40b18660bc884ebccd46fe8ac83604ac6d0f9d6c"

PYPI_PACKAGE = "spsdk_pkcs11"

inherit pypi python_setuptools_build_meta

RDEPENDS:${PN} += " \
    python3-asn1crypto \
    python3-cached-property \
    python3-pkcs11 (>= 0.8.1) \
    python3-spsdk (>= 3.10.0) \
"

BBCLASSEXTEND = "native"
