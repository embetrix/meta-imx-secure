# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Deploy an eMMC flashing script beside the image artifacts

IMX_FLASH_EMMC_TEMPLATE ?= "${IMX_SECURE_BASE}/files/uuu/flash-emmc.uuu.in"
# USB boot uses the untagged image, while the WIC keeps the tagged copy
IMX_UUU_BOOTLOADER ?= "${@bb.utils.contains('IMX_SIGN_ENABLE', '1', 'imx-boot.sign', 'imx-boot', d)}"
do_image_complete[file-checksums] += "${IMX_FLASH_EMMC_TEMPLATE}:True"
IMAGE_POSTPROCESS_COMMAND += "imx_deploy_flash_emmc; "

python imx_deploy_flash_emmc() {
    from pathlib import Path

    script = Path(d.getVar("IMX_FLASH_EMMC_TEMPLATE")).read_text()
    script = script.replace("@MACHINE@", d.getVar("MACHINE"))
    script = script.replace("@BOOTLOADER@", d.getVar("IMX_UUU_BOOTLOADER"))
    script = script.replace("@IMAGE@", d.getVar("IMAGE_LINK_NAME"))

    deploy = Path(d.getVar("IMGDEPLOYDIR"))
    deploy.mkdir(parents=True, exist_ok=True)
    (deploy / ("flash-emmc-%s.uuu" % d.getVar("MACHINE"))).write_text(script)
}
