# SPDX-License-Identifier: MIT
SUMMARY = "click plugin to show the command tree of your CLI"
HOMEPAGE = "https://github.com/whwright/click-command-tree"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=122e43f068614f96d22b996070de2fd3"

SRC_URI[sha256sum] = "3e7f5db9f3eccc2eccab40f7979355efe6d5123c958b748dee9c242a38364d6c"

PYPI_PACKAGE = "click_command_tree"

inherit pypi setuptools3

S = "${UNPACKDIR}/click-command-tree-${PV}"

RDEPENDS:${PN} += " \
    python3-click \
"

BBCLASSEXTEND = "native"
