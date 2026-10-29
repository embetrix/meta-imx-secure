# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Use the BSP boot flow for signed AHAB targets
IMX_FIT_BOOT_CONFIG ?= "${@bb.utils.contains('IMX_SIGN_ENABLE', '1', \
    bb.utils.contains('UBOOT_SECURE_BOOT_CONFIG', 'file://ahab.cfg', \
        'fit-ahab.cfg', 'fit-mmc.cfg', d), \
    'fit-mmc.cfg', d)}"

SRC_URI:append = " file://fit.cfg \
                   file://${IMX_FIT_BOOT_CONFIG} \
                   file://fit-boot.dtsi;subdir=${BP}/include \
                   ${@bb.utils.contains('UBOOT_SIGN_ENABLE', '1', 'file://0001-bootm-always-verify-signed-fit.patch', '', d)}"

do_uboot_assemble_fitimage[file-checksums] += "${@imx_fit_key_checksums(d)}"

# OE-Core only warns when the control DTB is missing
concat_dtb:prepend() {
    test -f "${UBOOT_DTB_BINARY}" || bbfatal "Missing U-Boot control DTB for FIT verification"
    test -f "${UBOOT_NODTB_BINARY}" || bbfatal "Missing U-Boot binary for FIT verification"
}

UBOOT_SECURE_BOOT_CONFIG = ""
UBOOT_SECURE_BOOT_CONFIG:mx8-generic-bsp  = "file://ahab.cfg"
UBOOT_SECURE_BOOT_CONFIG:mx9-generic-bsp  = "file://ahab.cfg"
UBOOT_SECURE_BOOT_CONFIG:mx8m-generic-bsp = "file://hab.cfg"

# Leave production hardening disabled until the i.MX95 boot issue is fixed
SRC_URI:append = " ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', d.getVar('UBOOT_SECURE_BOOT_CONFIG'), '', d)}"
