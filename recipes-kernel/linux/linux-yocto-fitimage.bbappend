# SPDX-License-Identifier: MIT

do_compile[file-checksums] += "${@imx_fit_key_checksums(d, 'FIT_KERNEL_SIGN')}"
do_compile[depends] += "${@bb.utils.contains('UBOOT_SIGN_ENABLE', '1', 'virtual/bootloader:do_deploy', '', d)}"

# NXP machine settings can list the same DTB more than once
python do_compile:prepend() {
    d.setVar("KERNEL_DEVICETREE", " ".join(dict.fromkeys(d.getVar("KERNEL_DEVICETREE").split())))
}

# Check the FIT against the key shipped in U-Boot
python do_compile:append() {
    if d.getVar("UBOOT_SIGN_ENABLE") == "1":
        bb.process.run([d.getVar("UBOOT_FIT_CHECK_SIGN"),
                        "-k", os.path.join(d.getVar("DEPLOY_DIR_IMAGE"), "u-boot.dtb"),
                        "-f", os.path.join(d.getVar("B"), "fitImage")])
}
