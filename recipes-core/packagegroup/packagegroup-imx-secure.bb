# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

SUMMARY = "i.MX security runtime support"
LICENSE = "MIT"

PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

IMX_SECURE_ENCLAVE_PACKAGES ?= ""
IMX_SECURE_ENCLAVE_PACKAGES:mx91-nxp-bsp = "imx-secure-enclave"
IMX_SECURE_ENCLAVE_PACKAGES:mx93-nxp-bsp = "imx-secure-enclave"
IMX_SECURE_ENCLAVE_PACKAGES:mx95-nxp-bsp = "imx-secure-enclave imx-secure-enclave-seco"

RDEPENDS:${PN} = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'optee-client optee-os smw', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', \
        bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', 'optee-pqc', '', d), '', d)} \
    ${IMX_SECURE_ENCLAVE_PACKAGES} \
"
