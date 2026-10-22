# SPDX-License-Identifier: MIT

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fit.cfg"
SRC_URI:append:imx91-11x11-lpddr4-frdm = " file://fit-imx91.cfg \
                                           file://0001-imx91-frdm-apply-fit-boot-defaults.patch"
SRC_URI:append:imx93-11x11-lpddr4x-frdm = " file://fit-imx93.cfg \
                                            file://0001-imx93-frdm-apply-fit-boot-defaults.patch"

SRC_URI:append:mx95-generic-bsp = " file://fit-imx95.cfg \
                                    file://0001-imx95-frdm-apply-fit-boot-defaults.patch"

UBOOT_SECURE_BOOT_CONFIG = ""
UBOOT_SECURE_BOOT_CONFIG:mx8-generic-bsp = "file://ahab.cfg"
UBOOT_SECURE_BOOT_CONFIG:mx9-generic-bsp = "file://ahab.cfg"
UBOOT_SECURE_BOOT_CONFIG:mx8m-generic-bsp = "file://hab.cfg"

IMX_SIGN_ENABLE ??= "0"

SRC_URI:append = " ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', d.getVar('UBOOT_SECURE_BOOT_CONFIG'), '', d)}"
