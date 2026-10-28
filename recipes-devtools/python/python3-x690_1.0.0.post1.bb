# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Pure Python X.690 implementation"
HOMEPAGE = "https://exhuma.github.io/x690/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=32e321618dd99d9983a92a83fa679f55"

SRC_URI[sha256sum] = "3a2a8a4e479079188aa6e847814981286b8f1c19569898fa3fe573ee0ce05349"

inherit pypi python_setuptools_build_meta

RDEPENDS:${PN} += " \
    python3-t61codec \
"

BBCLASSEXTEND = "native"
