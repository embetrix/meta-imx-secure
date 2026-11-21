# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Sign and verify i.MX8/9 AHAB boot images using SPSDK:
# https://github.com/nxp-mcuxpresso/spsdk
# NXP direct signing guide, section 11:
# https://community.nxp.com/t5/Multi-Source-Translation-Content/2377244-en-US/ta-p/2386026
# AHAB only, HABv4 signing is not implemented
# Family and revision support depends on the installed SPSDK version
#
# Sign unsigned and OEM containers, preserving NXP and V2X containers
# Verify OEM signatures, image hashes and unchanged image data and metadata
# Keep unsigned build outputs and deploy verified copies as <image>.sign
# Deploy imx-boot.sign and imx-boot.tagged.sign for the BSP's default image
# Deploy SPSDK SRK hashes and fuse scripts in <image>.fuses/
# This class does not program SRK hash fuses or change the device lifecycle
#
# Generate keys and a kas fragment with tools/generate-signing-keys.sh --key-dir <KEY_DIR>, then run:
# kas build kas-imx-secure.yml:kas-signing-keys.yml
# Or enable in local.conf or distro configuration with existing keys:
# INHERIT += "imx-signing-keys"
# IMX_SIGN_ENABLE = "1"
# IMX_SIGN_KEYDIR = "/path/to/signing-keys"
# Set IMX_SIGN_DEBUG = "1" to show signing details in the build console
#
# Shared key settings and SPSDK helpers
inherit imx-ahab-sign-common

# Select the memory type for each UBOOT_CONFIG entry, with a fallback for raw SD/eMMC images
# Override the fallback or add mappings such as IMX_SPSDK_MEMORY_TYPE[custom] = "flexspi_nor"
IMX_SPSDK_MEMORY_TYPE ??= "serial_downloader"
IMX_SPSDK_MEMORY_TYPE[fspi] ?= "flexspi_nor"

IMX_SIGN_OUTPUT_DIR = "${WORKDIR}/imx-boot-signed"

def imx_sign_images(d):
    configs = (d.getVar("UBOOT_CONFIG") or "").split()
    targets = (d.getVar("IMXBOOT_TARGETS") or "").split()
    if not configs or not targets:
        bb.fatal("imx-boot signing needs UBOOT_CONFIG and IMXBOOT_TARGETS")
    for config in configs:
        for target in targets:
            name = "imx-boot%s-%s-%s.bin-%s" % (
                d.getVar("BOOT_VARIANT") or "", d.getVar("MACHINE"), config, target)
            yield config, name

python do_imx_boot_sign() {
    for config, name in imx_sign_images(d):
        memory = d.getVarFlag("IMX_SPSDK_MEMORY_TYPE", config) or d.getVar("IMX_SPSDK_MEMORY_TYPE")
        imx_ahab_run(d, os.path.join(d.getVar("S"), name),
                    os.path.join(d.getVar("IMX_SIGN_OUTPUT_DIR"), name),
                    ["--memory-type", memory])
}
do_imx_boot_sign[cleandirs] = "${IMX_SIGN_OUTPUT_DIR}"
do_imx_boot_sign[vardeps] += "IMX_SPSDK_MEMORY_TYPE UBOOT_CONFIG IMXBOOT_TARGETS BOOT_VARIANT MACHINE"

python imx_sign_deploy() {
    import shutil
    from pathlib import Path

    source = Path(d.getVar("IMX_SIGN_OUTPUT_DIR"))
    deploy = Path(d.getVar("DEPLOYDIR"))
    images = list(imx_sign_images(d))
    default = (deploy / "imx-boot").resolve().name
    if default not in [name for config, name in images]:
        bb.fatal("No signed variant for deployed imx-boot: %s" % default)

    # This hook runs only after every variant has passed signing and verification
    for config, name in images:
        shutil.copy2(source / name, deploy / (name + ".sign"))
        shutil.copytree(source / (name + ".fuses"), deploy / (name + ".fuses"),
                        dirs_exist_ok=True)

    link = deploy / "imx-boot.sign"
    link.unlink(missing_ok=True)
    link.symlink_to(default + ".sign")

    tagged = deploy / "imx-boot.tagged.sign"
    shutil.copy2(link, tagged)
    # Match the size tag appended by uuu_bootloader_tag.bbclass
    size = tagged.stat().st_size
    with tagged.open("ab") as output:
        output.write(("UUUBURNXXOEUZX7+A-XY5601QQWWZ%dEND\n" % size).encode("ascii"))
}

python __anonymous() {
    if d.getVar("IMX_SIGN_ENABLE") != "1":
        imx_validate_signing_keys(d)
        return
    imx_ahab_validate(d)
    list(imx_sign_images(d))
    imx_ahab_setup(d, "do_imx_boot_sign")
    # Copy before deploy's sstate postfunc publishes DEPLOYDIR
    d.prependVarFlag("do_deploy", "postfuncs", "imx_sign_deploy ")
    bb.build.addtask("do_imx_boot_sign", "do_deploy", "do_compile", d)
}
