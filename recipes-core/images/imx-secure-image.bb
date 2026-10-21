# SPDX-License-Identifier: MIT
SUMMARY = "Minimal console image for meta-imx-secure"
LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"
IMAGE_LINGUAS = " "
