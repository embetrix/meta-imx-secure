# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Deploy an eMMC flashing script beside the image artifacts

IMX_FLASH_EMMC_TEMPLATE ?= "${IMX_SECURE_BASE}/files/uuu/flash-emmc.uuu.in"
# USB boot uses the untagged image, while the WIC keeps the tagged copy
IMX_UUU_BOOTLOADER ?= "${@bb.utils.contains('IMX_SIGN_ENABLE', '1', 'imx-boot.sign', 'imx-boot', d)}"
do_image_complete[file-checksums] += "${IMX_FLASH_EMMC_TEMPLATE}:True"
do_image_complete[depends] += "imx-boot:do_deploy"
IMAGE_POSTPROCESS_COMMAND += "imx_deploy_flash_emmc; "

python imx_deploy_flash_emmc() {
    from pathlib import Path

    secondary_offset = int(d.getVar("IMX_BOOT_SECONDARY_OFFSET"), 0)
    boot_size = int(d.getVar("IMX_BOOT_MAX_SIZE"), 0)
    primary_offset = int(d.getVar("IMX_BOOT_SEEK")) * 1024
    if secondary_offset <= 0 or boot_size <= 0 or secondary_offset % 512 or boot_size % 512:
        bb.fatal("Boot firmware offset and size must be positive multiples of 512 bytes")
    # The WIC layout starts boot_a at 8 MiB
    if secondary_offset < primary_offset + boot_size or secondary_offset + boot_size > 8 * 1024 * 1024:
        bb.fatal("Secondary boot firmware must fit between the primary firmware area and boot_a")

    # Jenkins archives real files, not the deploy symlinks
    bootloader = (Path(d.getVar("DEPLOY_DIR_IMAGE")) / d.getVar("IMX_UUU_BOOTLOADER")).resolve(strict=True)
    script = Path(d.getVar("IMX_FLASH_EMMC_TEMPLATE")).read_text()
    script = script.replace("@MACHINE@", d.getVar("MACHINE"))
    script = script.replace("@BOOTLOADER@", bootloader.name)
    script = script.replace("@IMAGE@", d.getVar("IMAGE_NAME"))
    script = script.replace("@SECONDARY_BOOT_SIZE@", hex(boot_size))
    script = script.replace("@SECONDARY_BOOT_BLOCK@", hex(secondary_offset // 512))
    script = script.replace("@SECONDARY_BOOT_BLOCKS@", hex(boot_size // 512))

    deploy = Path(d.getVar("IMGDEPLOYDIR"))
    deploy.mkdir(parents=True, exist_ok=True)
    (deploy / ("flash-emmc-%s.uuu" % d.getVar("MACHINE"))).write_text(script)
}
