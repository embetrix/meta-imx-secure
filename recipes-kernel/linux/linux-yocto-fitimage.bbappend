# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Embetrix Embedded Systems Solutions <ayoub.zaki@embetrix.com>

do_compile[file-checksums] += "${@imx_fit_key_checksums(d, 'FIT_KERNEL_SIGN')}"
do_compile[depends] += "${@bb.utils.contains('UBOOT_SIGN_ENABLE', '1', 'virtual/bootloader:do_deploy', '', d)}"

python __anonymous() {
    if d.getVar("UBOOT_SIGN_ENABLE") == "1" and d.getVar("FIT_KERNEL_SIGN_ENABLE") != "1":
        bb.fatal("FIT_KERNEL_SIGN_ENABLE must be 1 when UBOOT_SIGN_ENABLE is 1")
    imx_validate_fit_signing_keys(d, "FIT_KERNEL_SIGN")
}

# NXP machine settings can list the same DTB more than once
python do_compile:prepend() {
    d.setVar("KERNEL_DEVICETREE", " ".join(dict.fromkeys(d.getVar("KERNEL_DEVICETREE").split())))
}

# Check the FIT against the key shipped in U-Boot
python do_compile:append() {
    if d.getVar("UBOOT_SIGN_ENABLE") == "1":
        try:
            bb.process.run([d.getVar("UBOOT_FIT_CHECK_SIGN"),
                            "-k", os.path.join(d.getVar("DEPLOY_DIR_IMAGE"), "u-boot.dtb"),
                            "-f", os.path.join(d.getVar("B"), "fitImage")])
        except bb.process.ExecutionError as error:
            bb.fatal("FIT signature verification failed:\n%s" % error)
}
