# SPDX-License-Identifier: MIT

INHERIT += "imx-signing-keys"

# Provide kernel artifacts for FIT generation alongside Image
KERNEL_CLASSES:append = " kernel-fit-extra-artifacts"
UBOOT_ENTRYPOINT:mx91-generic-bsp ?= "0x80400000"
UBOOT_ENTRYPOINT:mx95-generic-bsp ?= "0x90400000"

IMAGE_BOOT_FILES:append = " fitImage"
do_image_wic[depends] += "linux-yocto-fitimage:do_deploy"
