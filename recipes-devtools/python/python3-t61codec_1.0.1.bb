# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Python Character Mapping Codec for T61"
HOMEPAGE = "https://github.com/exhuma/t61codec"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=cc5ee59e5774aa449f71b7d02433ddf3"

SRC_URI += "file://0001-allow-flit-core-3.patch"

SRC_URI[sha256sum] = "4d854f40017ef39e699291a57a9891c74630facb370b94238284eb9a475ae23f"

inherit pypi python_flit_core

BBCLASSEXTEND = "native"
