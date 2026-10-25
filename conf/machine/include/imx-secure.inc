# SPDX-License-Identifier: MIT

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
ROOTFS_TYPE ?= "ext4"
IMAGE_FSTYPES += "wic.gz wic.bmap"
