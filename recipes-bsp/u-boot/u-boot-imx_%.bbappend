# SPDX-License-Identifier: MIT

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

IMX_SIGN_ENABLE ??= "0"

UBOOT_SECURE_BOOT_CONFIG = ""
UBOOT_SECURE_BOOT_CONFIG:mx8-generic-bsp = "file://ahab.cfg"
UBOOT_SECURE_BOOT_CONFIG:mx9-generic-bsp = "file://ahab.cfg"
UBOOT_SECURE_BOOT_CONFIG:mx8m-generic-bsp = "file://hab.cfg"

SRC_URI:append = " ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', d.getVar('UBOOT_SECURE_BOOT_CONFIG'), '', d)}"
