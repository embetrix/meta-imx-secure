# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Read and write hexadecimal dumps"
HOMEPAGE = "https://pypi.org/project/hexdump/"
LICENSE = "PD"
LIC_FILES_CHKSUM = "file://PKG-INFO;beginline=8;endline=8;md5=b46c242890afc1ecfe0faa5b6dcf2a69"

PYPI_PACKAGE_EXT = "zip"
SRC_URI[sha256sum] = "d781a43b0c16ace3f9366aade73e8ad3a7bd5137d58f0b45ab2d3f54876f20db"

inherit pypi setuptools3

# This archive has no top directory
PYPI_SRC_URI .= ";subdir=${BP}"
S = "${UNPACKDIR}/${BP}"

# Drop upstream's sample data
do_install:append() {
    rm -rf ${D}${prefix}/data
}

RDEPENDS:${PN} += "python3-codecs python3-io"

BBCLASSEXTEND = "native"
