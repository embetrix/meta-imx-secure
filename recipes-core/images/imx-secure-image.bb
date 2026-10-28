# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "Minimal image for meta-imx-secure"
LICENSE = "MIT"

inherit core-image

IMAGE_FEATURES:append = " read-only-rootfs ssh-server-openssh"

IMAGE_INSTALL += " \
    packagegroup-security-base \
    packagegroup-imx-security \
    ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', 'packagegroup-dev', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'packagegroup-fsl-optee-imx', '', d)} \
"
