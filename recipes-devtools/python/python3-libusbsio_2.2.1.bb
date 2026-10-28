# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Python wrapper around NXP LIBUSBSIO library"
HOMEPAGE = "https://www.nxp.com/libusbsio"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = " \
    file://LICENSE.txt;md5=5b6b7f04e1394b554d36c93c4abdb23b \
    file://LICENSE-hidapi-bsd.txt;md5=146f1fc708cdb0edb71523b71655411a \
"

SRC_URI[sha256sum] = "65c7180d7f7717670d8c3c320f1a3f45d5c73bb13c6576790fc1a7818e380254"

inherit pypi python_setuptools_build_meta

RDEPENDS:${PN} += " \
    python3-ctypes \
    python3-logging \
    python3-threading \
"

BBCLASSEXTEND = "native"

# Upstream ships the USB library as a prebuilt binary
COMPATIBLE_HOST = "(aarch64|x86_64).*-linux$"
LIBUSBSIO_ARCH = "${TARGET_ARCH}"
LIBUSBSIO_ARCH:class-native = "${BUILD_ARCH}"

RDEPENDS:${PN}:append:class-target = " libudev"

# Keep only the library for this build
do_install:append() {
    for dir in ${D}${PYTHON_SITEPACKAGES_DIR}/libusbsio/bin/*; do
        if [ "$(basename "$dir")" != "linux_${LIBUSBSIO_ARCH}" ]; then
            rm -rf "$dir"
        fi
    done
}

INSANE_SKIP:${PN} += "already-stripped"
