# SPDX-License-Identifier: MIT
SUMMARY = "Minimal image for meta-imx-secure"
LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL += " \
    packagegroup-security-base \
    packagegroup-imx-security \
    packagegroup-dev \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'packagegroup-fsl-optee-imx', '', d)} \
"
