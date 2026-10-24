# SPDX-License-Identifier: MIT
SUMMARY = "Minimal console image for meta-imx-secure"
LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL += " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'packagegroup-fsl-optee-imx', '', d)} \
    packagegroup-core-full-cmdline \
"
