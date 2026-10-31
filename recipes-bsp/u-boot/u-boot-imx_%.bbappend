# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Use the BSP boot flow for signed AHAB targets
IMX_FIT_BOOT_CONFIG ?= "${@bb.utils.contains('IMX_SIGN_ENABLE', '1', \
                                    bb.utils.contains('UBOOT_SECURE_BOOT_CONFIG', 'file://ahab.cfg', \
                                    'fit-ahab.cfg', 'fit-mmc.cfg', d), \
                                    'fit-mmc.cfg', d)}"

SRC_URI:append = " file://fit.cfg \
                   file://env-fdt.cfg \
                   file://mmc-boot-parts.cfg \
                   file://${IMX_FIT_BOOT_CONFIG} \
                   file://fit-boot.dtsi;subdir=${BP}/include \
                   ${@bb.utils.contains('UBOOT_SIGN_ENABLE', '1', 'file://0001-bootm-always-verify-signed-fit.patch', '', d)} \
                   file://0002-spl-print-container-software-version.patch \
                   file://0004-imx-select-mmc-boot-partition.patch"

# Provide a fresh KASLR seed from ELE on i.MX9
SRC_URI:append:mx9-generic-bsp = " file://rng-ele.cfg \
                                   file://0003-rng-ele-include-allocation-and-cache-headers.patch"

# The i.MX95 FRDM defconfig lacks the shared buffer set by the EVK defconfig
SRC_URI:append:imx95-15x15-lpddr4x-frdm = " file://rng-ele-imx95.cfg"

do_uboot_assemble_fitimage[file-checksums] += "${@imx_fit_key_checksums(d)}"

UBOOT_SECURE_BOOT_CONFIG = ""
UBOOT_SECURE_BOOT_CONFIG:mx8-generic-bsp  = "file://ahab.cfg"
UBOOT_SECURE_BOOT_CONFIG:mx9-generic-bsp  = "file://ahab.cfg"
UBOOT_SECURE_BOOT_CONFIG:mx8m-generic-bsp = "file://hab.cfg"

SRC_URI:append = " ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', d.getVar('UBOOT_SECURE_BOOT_CONFIG'), '', d)}"
SRC_URI:append = " ${@bb.utils.contains('IMX_SECURITY_PROFILE', 'prod', 'file://security-harden.cfg', '', d)}"
