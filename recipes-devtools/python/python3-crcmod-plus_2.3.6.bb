# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "CRC generator with a Python and C implementation"
HOMEPAGE = "https://github.com/ntamas/crcmod-plus"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=f9a19291627cad2d1dfbfcf3c9fb85c2"

PYPI_PACKAGE = "crcmod_plus"
SRC_URI[sha256sum] = "d18de4d8f00a1db9747a104daa13b1164ef82e5bd684dedd9d03ecbca52c5af0"

inherit pypi python_setuptools_build_meta

RDEPENDS:${PN} += "python3-core"
RPROVIDES:${PN} += "python3-crcmod"
RREPLACES:${PN} += "python3-crcmod"
RCONFLICTS:${PN} += "python3-crcmod"

BBCLASSEXTEND = "native nativesdk"
