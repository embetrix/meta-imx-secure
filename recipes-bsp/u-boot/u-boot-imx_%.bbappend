# SPDX-License-Identifier: MIT

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fit.cfg \
                   file://fit-mmc.cfg \
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

IMX_SIGN_ENABLE ??= "0"

SRC_URI:append = " ${@bb.utils.contains('IMX_SIGN_ENABLE', '1', d.getVar('UBOOT_SECURE_BOOT_CONFIG'), '', d)}"
