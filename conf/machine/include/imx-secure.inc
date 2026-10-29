# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

INHERIT += "imx-signing-keys"

UBOOT_SIGN_ENABLE ?= "${@d.getVar('IMX_SIGN_ENABLE') or '0'}"
UBOOT_SIGN_KEYDIR ?= ""
UBOOT_SIGN_KEYNAME ?= "fit"
FIT_SIGN_ALG ?= "rsa2048"
FIT_SIGN_INDIVIDUAL = "0"

# Provide kernel artifacts for FIT generation alongside Image
KERNEL_CLASSES:append = " kernel-fit-extra-artifacts"

# i.MX91 and i.MX95 entry points are missing from meta-freescale's imx-base.inc
UBOOT_ENTRYPOINT:mx91-generic-bsp ?= "0x80400000"
UBOOT_ENTRYPOINT:mx95-generic-bsp ?= "0x90400000"

# Keep BSP additions out of the active boot partition
IMAGE_BOOT_FILES_label-bootA = "fitImage"
WICVARS:append = " IMAGE_BOOT_FILES_label-bootA"
do_image_wic[depends] += "linux-yocto-fitimage:do_deploy"

WKS_FILE = "imx-boot-secure-bootpart.wks.in"
IMX_BOOTLOADER ?= "${@bb.utils.contains('IMX_SIGN_ENABLE', '1', \
    'imx-boot.tagged.sign', 'imx-boot.tagged', d)}"

ROOTFS_TYPE  ?= "ext4"
IMAGE_FSTYPES += "wic.gz wic.bmap ${ROOTFS_TYPE}.avbverity.gz"

BOOT_PART_SZ ?= "512M"
BLOB_PART_SZ ?= "512M"
ROOT_PART_SZ ?= "1024M"
DATA_PART_SZ ?= "4096M"
