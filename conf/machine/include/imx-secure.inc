# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Shared signing key checks
INHERIT += "imx-signing-keys"

# Use the NXP BSP and keep our linux-imx security settings
IMX_DEFAULT_BSP = "nxp"
IMX_DEFAULT_KERNEL:imx-nxp-bsp = "linux-imx"

# Default PKCS#11 library
OPENSSL_PKCS11_DEFAULT_PROVIDER ??= "optee"

# Machine runtime support
IMX_SECURE_ENCLAVE_PACKAGES ?= ""
IMX_SECURE_ENCLAVE_PACKAGES:mx91-nxp-bsp = "imx-secure-enclave"
IMX_SECURE_ENCLAVE_PACKAGES:mx93-nxp-bsp = "imx-secure-enclave"
IMX_SECURE_ENCLAVE_PACKAGES:mx95-nxp-bsp = "imx-secure-enclave imx-secure-enclave-seco"

# NXP Wi-Fi feature mappings missing from meta-freescale
MACHINE_EXTRA_RRECOMMENDS:append = " ${@bb.utils.contains_any('MACHINE_FEATURES', \
    'nxpwifi-all-sdio nxpwifi-all-pcie nxpwifi-all-usb nxpiw610-sdio nxpaw693-pcie nxpaw693-sdio', \
    'kernel-module-nxp-wlan', '', d)}"
MACHINE_FIRMWARE:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'nxpwifi-all-sdio', 'firmware-nxp-wifi-all-sdio', '', d)}"
MACHINE_FIRMWARE:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'nxpwifi-all-pcie', 'firmware-nxp-wifi-all-pcie', '', d)}"
MACHINE_FIRMWARE:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'nxpwifi-all-usb', 'firmware-nxp-wifi-all-usb', '', d)}"
MACHINE_FIRMWARE:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'nxpiw610-sdio', 'firmware-nxp-wifi-nxpiw610-sdio', '', d)}"
MACHINE_FIRMWARE:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'nxpaw693-pcie', 'firmware-nxp-wifi-nxpaw693-pcie', '', d)}"
MACHINE_FIRMWARE:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'nxpaw693-sdio', 'firmware-nxp-wifi-nxpaw693-sdio', '', d)}"

# Enable optee-ftpm
MACHINE_FEATURES:append = " optee-ftpm"

MACHINE_EXTRA_RDEPENDS:append = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'optee-client optee-os smw', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'optee', \
        bb.utils.contains('IMX_SECURITY_PROFILE', 'dev', 'optee-pqc', '', d), '', d)} \
    ${IMX_SECURE_ENCLAVE_PACKAGES} \
"

# FIT signing
UBOOT_SIGN_ENABLE ?= "${@d.getVar('IMX_SIGN_ENABLE') or '0'}"
UBOOT_SIGN_KEYDIR ?= ""
UBOOT_SIGN_KEYNAME ?= "fit"
FIT_SIGN_ALG ?= "rsa2048"
FIT_SIGN_INDIVIDUAL = "0"

# AHAB wrapper for the signed FIT
# U-Boot authenticates the container before booting the extracted FIT
# Enable by default when boot signing and a destination address are configured
IMX_FIT_AHAB_ENABLE ?= "${@bb.utils.contains('IMX_SIGN_ENABLE', '1', \
    '1' if d.getVar('IMX_FIT_AHAB_LOAD_ADDRESS') else '0', '0', d)}"

# AHAB FIT destination addresses
IMX_FIT_AHAB_LOAD_ADDRESS:mx8qm-generic-bsp  ?= "0x90000000"
IMX_FIT_AHAB_LOAD_ADDRESS:mx8qxp-generic-bsp ?= "0x90000000"
IMX_FIT_AHAB_LOAD_ADDRESS:mx8dxl-generic-bsp ?= "0x90000000"
IMX_FIT_AHAB_LOAD_ADDRESS:mx8ulp-generic-bsp ?= "0x90000000"
IMX_FIT_AHAB_LOAD_ADDRESS:mx91-generic-bsp   ?= "0x90000000"
IMX_FIT_AHAB_LOAD_ADDRESS:mx93-generic-bsp   ?= "0x90000000"
IMX_FIT_AHAB_LOAD_ADDRESS:mx95-generic-bsp   ?= "0xa0000000"

# Provide kernel artifacts for FIT generation alongside Image
KERNEL_CLASSES:append = " kernel-fit-extra-artifacts"

# i.MX91 and i.MX95 entry points are missing from meta-freescale's imx-base.inc
UBOOT_ENTRYPOINT:mx91-generic-bsp ?= "0x80400000"
UBOOT_ENTRYPOINT:mx95-generic-bsp ?= "0x90400000"

# Initramfs Bundle
INITRAMFS_IMAGE        ?= "imx-secure-initramfs-image"
INITRAMFS_IMAGE_NAME   ?= "imx-secure-initramfs-image-${MACHINE}.rootfs"
INITRAMFS_IMAGE_BUNDLE  = "1"

# Boot image and disk layout
IMX_BOOTLOADER ?= "${@bb.utils.contains('IMX_SIGN_ENABLE', '1', \
    'imx-boot.tagged.sign', 'imx-boot.tagged', d)}"
# Byte offset of the second boot firmware copy
IMX_BOOT_SECONDARY_OFFSET ?= "0x400000"
# Maximum boot firmware size: 4,161,536 bytes (4 MiB minus 32 KiB)
IMX_BOOT_MAX_SIZE ?= "0x3f8000"
WKS_FILE = "imx-boot-secure-bootpart.wks.in"

# Keep BSP additions out of the active boot partition
IMAGE_BOOT_FILES = "${@bb.utils.contains('IMX_FIT_AHAB_ENABLE', '1', 'fitImage.ahab;fitImage', 'fitImage', d)}"
WICVARS:append = " IMAGE_BOOT_FILES_label-boot_a"
do_image_wic[depends] += "linux-yocto-fitimage:do_deploy"

# Root filesystem and output formats
ROOTFS_TYPE ?= "erofs"
AVB_ROOT_HASH_SIGN ?= "1"
IMAGE_FSTYPES += "wic.gz wic.bmap ${ROOTFS_TYPE}.avbverity.gz tar.zst"

# Deploy the eMMC flashing script only with complete disk images
IMAGE_CLASSES += "${@bb.utils.contains('IMAGE_FSTYPES', 'wic.gz wic.bmap', 'imx-image-uuu', '', d)}"

# Partition sizes
BOOT_PART_SZ ?= "512M"
ROOT_PART_SZ ?= "1024M"
SECDATA_PART_SZ ?= "512M"
DATA_PART_SZ ?= "3072M"
