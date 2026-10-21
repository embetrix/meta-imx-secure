# SPDX-License-Identifier: MIT
SUMMARY = "Minimal console image for meta-imx-secure"
LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL += " \
    packagegroup-core-full-cmdline \
"
