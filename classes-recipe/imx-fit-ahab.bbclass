# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

# Wrap the complete FIT in a signed AHAB OS container
# Enable with IMX_FIT_AHAB_ENABLE = "1" in the build configuration
# Set IMX_FIT_AHAB_LOAD_ADDRESS to free DDR space on the target
# Keep it separate from the container buffer and kernel decompression area
# This class only deploys fitImage.ahab and does not change the boot flow

inherit imx-ahab-sign

IMX_FIT_AHAB_LOAD_ADDRESS ??= ""
IMX_FIT_AHAB_CORE ??= "cortex-a55"
IMX_FIT_AHAB_CORE:mx8ulp-generic-bsp = "cortex-a35-1"
IMX_FIT_AHAB_CORE:mx8x-generic-bsp = "cortex-a35"
IMX_FIT_AHAB_CORE:mx8qm-generic-bsp = "cortex-a72"
IMX_FIT_AHAB_SW_VERSION ??= "1"
IMX_FIT_AHAB_OUTPUT_DIR = "${WORKDIR}/fit-ahab"

python do_imx_fit_ahab() {
    imx_ahab_run(d, os.path.join(d.getVar("B"), "fitImage"),
                os.path.join(d.getVar("IMX_FIT_AHAB_OUTPUT_DIR"), "fitImage.ahab"),
                ["--fit", "--load-address", d.getVar("IMX_FIT_AHAB_LOAD_ADDRESS"),
                 "--core", d.getVar("IMX_FIT_AHAB_CORE"),
                 "--sw-version", d.getVar("IMX_FIT_AHAB_SW_VERSION")])
}
do_imx_fit_ahab[cleandirs] = "${IMX_FIT_AHAB_OUTPUT_DIR}"

python imx_fit_ahab_deploy() {
    import shutil
    from pathlib import Path

    deploy = Path(d.getVar("DEPLOYDIR")) / (d.getVar("KERNEL_DEPLOYSUBDIR") or "")
    deploy.mkdir(parents=True, exist_ok=True)
    shutil.copy2(Path(d.getVar("IMX_FIT_AHAB_OUTPUT_DIR")) / "fitImage.ahab",
                 deploy / "fitImage.ahab")
}

python __anonymous() {
    if d.getVar("IMX_SIGN_ENABLE") != "1":
        bb.fatal("IMX_FIT_AHAB_ENABLE requires IMX_SIGN_ENABLE = '1'")
    imx_ahab_validate(d)
    try:
        address = int(d.getVar("IMX_FIT_AHAB_LOAD_ADDRESS"), 0)
        version = int(d.getVar("IMX_FIT_AHAB_SW_VERSION"), 0)
    except (TypeError, ValueError):
        bb.fatal("Set IMX_FIT_AHAB_LOAD_ADDRESS and IMX_FIT_AHAB_SW_VERSION to integers")
    if not 0 < address < 2**64 or address % 4:
        bb.fatal("IMX_FIT_AHAB_LOAD_ADDRESS must be positive, 4-byte aligned and fit in 64 bits")
    if not 0 <= version <= 0xffff:
        bb.fatal("IMX_FIT_AHAB_SW_VERSION must fit in 16 bits")
    imx_ahab_setup(d, "do_imx_fit_ahab")
    d.prependVarFlag("do_deploy", "postfuncs", "imx_fit_ahab_deploy ")
    bb.build.addtask("do_imx_fit_ahab", "do_deploy", "do_compile", d)
}
