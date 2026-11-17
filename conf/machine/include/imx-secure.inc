# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Shared signing key checks
INHERIT += "imx-signing-keys"

# Default PKCS#11 library
OPENSSL_PKCS11_DEFAULT_PROVIDER ??= "optee"

# Machine runtime support
IMX_SECURE_ENCLAVE_PACKAGES ?= ""
IMX_SECURE_ENCLAVE_PACKAGES:mx91-nxp-bsp = "imx-secure-enclave"
IMX_SECURE_ENCLAVE_PACKAGES:mx93-nxp-bsp = "imx-secure-enclave"
IMX_SECURE_ENCLAVE_PACKAGES:mx95-nxp-bsp = "imx-secure-enclave imx-secure-enclave-seco"

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
WKS_FILE = "imx-boot-secure-bootpart.wks.in"

# Keep BSP additions out of the active boot partition
IMAGE_BOOT_FILES = "${@bb.utils.contains('IMX_FIT_AHAB_ENABLE', '1', 'fitImage.ahab;fitImage', 'fitImage', d)}"
WICVARS:append = " IMAGE_BOOT_FILES_label-boot_a"
do_image_wic[depends] += "linux-yocto-fitimage:do_deploy"

# Root filesystem and output formats
ROOTFS_TYPE ?= "erofs"
AVB_ROOT_HASH_SIGN ?= "1"
IMAGE_FSTYPES += "wic.gz wic.bmap ${ROOTFS_TYPE}.avbverity.gz"

# Partition sizes
BOOT_PART_SZ ?= "512M"
ROOT_PART_SZ ?= "1024M"
SECDATA_PART_SZ ?= "512M"
DATA_PART_SZ ?= "4096M"
