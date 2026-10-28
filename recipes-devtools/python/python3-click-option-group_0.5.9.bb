# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Option groups missing in Click"
HOMEPAGE = "https://github.com/click-contrib/click-option-group"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=0b41de2509ab6cfdc7b957c8e82956d0"

SRC_URI[sha256sum] = "f94ed2bc4cf69052e0f29592bd1e771a1789bd7bfc482dd0bc482134aff95823"

PYPI_PACKAGE = "click_option_group"

inherit pypi python_hatchling

DEPENDS += "python3-hatch-vcs-native"

RDEPENDS:${PN} += " \
    python3-click \
"

BBCLASSEXTEND = "native"
